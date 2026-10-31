import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../platform/native_bridge.dart';
import '../../features/scan/domain/scan_result.dart';
import 'cognitive_analyzer.dart';
import 'number_utils.dart';
import 'privacy_sanitizer.dart';
import 'rule_engine.dart';
import 'spam_directory.dart';
import 'threat_list_store.dart';

abstract final class ScanActions {
  static const popupAndSound = 'SHOW_POPUP_ALERT_AND_SOUND';
  static const notifyWarning = 'SHOW_NOTIFICATION_WARNING';
  static const none = 'NONE';
}

/// Pipeline deteksi hibrida 4 lapis. Berhenti di lapis pertama yang yakin,
/// sehingga latensi dan biaya token AI tetap kecil.
///
/// 1. Offline filter (blocklist + Bloom Filter)
/// 2. DB lookup komunitas (Firestore `spam_summaries`)
/// 3. Rule engine (regex & parser finansial)
/// 4. Cognitive AI (Gemini + Nusantara NLP)
class DetectionPipeline {
  DetectionPipeline({
    required this._store,
    required this._directory,
    required this._analyzer,
    this._rules = const RuleEngine(),
  });

  final ThreatListStore _store;
  final SpamDirectory _directory;
  final CognitiveAnalyzer _analyzer;
  final RuleEngine _rules;

  Future<ScanResult> scan(IncomingNotification n) async {
    final watch = Stopwatch()..start();
    final platform =
        MessagePlatform.fromPackage(n.packageName) ?? MessagePlatform.sms;
    final key = senderKey(n.sender);

    ScanResult build({
      required RiskLevel risk,
      required String threat,
      required double confidence,
      required String summary,
      required int layer,
      ExtractedEntities entities = const ExtractedEntities(),
    }) {
      return ScanResult(
        scanId: _newId(),
        platform: platform,
        sender: n.sender,
        riskLevel: risk,
        threatType: threat,
        confidenceScore: double.parse(
          confidence.clamp(0, 1).toStringAsFixed(2),
        ),
        aiSummary: summary,
        entities: entities,
        actionRequired: switch (risk) {
          RiskLevel.high => ScanActions.popupAndSound,
          RiskLevel.medium => ScanActions.notifyWarning,
          RiskLevel.low => ScanActions.none,
        },
        scannedAt: DateTime.now(),
        decidedByLayer: layer,
        latencyMs: watch.elapsedMilliseconds,
      );
    }

    // ── Lapis 1: offline filter ──────────────────────────────────────────
    if (_store.isBlocked(key)) {
      return build(
        risk: RiskLevel.high,
        threat: ThreatCodes.knownScammer,
        confidence: 1,
        summary: 'Pengirim ini sudah Anda tandai sebagai penipu.',
        layer: 1,
      );
    }

    SpamEntry? entry;
    var directoryReachable = true;
    try {
      entry = await _directory.lookup(key);
    } on Object catch (e) {
      directoryReachable = false;
      debugPrint('Lapis 2 dilewati: $e');
    }

    if (_store.isKnownSpam(key)) {
      // Cocok di Bloom Filter. Bila server bisa dihubungi dan tidak menemukan
      // nomor itu, anggap false positive dan lanjutkan ke lapis berikutnya.
      if (entry != null || !directoryReachable) {
        return build(
          risk: RiskLevel.high,
          threat: ThreatCodes.knownScammer,
          confidence: 0.9,
          summary: entry != null && entry.aiSummary.isNotEmpty
              ? entry.aiSummary
              : 'Nomor ada di daftar penipu komunitas.',
          layer: 1,
        );
      }
    }

    // ── Lapis 2: laporan komunitas ───────────────────────────────────────
    var communityBoost = 0.0;
    if (entry != null) {
      if (entry.riskLevel == RiskLevel.high &&
          entry.reportCount >= AppConstants.communityHighThreshold) {
        return build(
          risk: RiskLevel.high,
          threat: ThreatCodes.knownScammer,
          confidence: (0.7 + 0.05 * entry.reportCount).clamp(0.0, 0.99),
          summary: entry.aiSummary.isNotEmpty
              ? entry.aiSummary
              : 'Nomor ini dilaporkan ${entry.reportCount} kali oleh komunitas.',
          layer: 2,
        );
      }
      communityBoost = 0.25; // pernah dilaporkan, belum cukup untuk memvonis
    }

    // ── Lapis 3: rule engine ─────────────────────────────────────────────
    final rule = _rules.analyze(n.body);
    final score = 1 - (1 - rule.score) * (1 - communityBoost);

    if (score >= RuleEngine.highThreshold) {
      return build(
        risk: RiskLevel.high,
        threat: rule.threatCode == ThreatCodes.none
            ? ThreatCodes.knownScammer
            : rule.threatCode,
        confidence: score,
        summary: _ruleSummary(rule),
        layer: 3,
        entities: rule.entities,
      );
    }
    if (score < RuleEngine.lowThreshold) {
      return build(
        risk: RiskLevel.low,
        threat: ThreatCodes.none,
        confidence: 1 - score,
        summary: 'Tidak ditemukan indikasi manipulasi atau tautan berbahaya.',
        layer: 3,
        entities: rule.entities,
      );
    }

    // ── Lapis 4: AI kognitif (hanya untuk kasus abu-abu) ─────────────────
    CognitiveVerdict? verdict;
    try {
      verdict = await _analyzer.analyze(
        platform: platform,
        text: sanitizeForAi(n.body),
        ruleSignals: rule.signals,
      );
    } on Object catch (e) {
      debugPrint('Lapis 4 dilewati: $e');
    }

    if (verdict != null) {
      var risk = verdict.riskLevel;
      // Jangan sepenuhnya mengabaikan sinyal aturan yang kuat.
      if (risk == RiskLevel.low && score >= 0.5) risk = RiskLevel.medium;
      return build(
        risk: risk,
        threat: verdict.threatCode != ThreatCodes.none
            ? verdict.threatCode
            : (risk == RiskLevel.low ? ThreatCodes.none : rule.threatCode),
        confidence: verdict.confidence,
        summary: verdict.summary.isNotEmpty
            ? verdict.summary
            : _ruleSummary(rule),
        layer: 4,
        entities: rule.entities,
      );
    }

    // AI tak tersedia (luring): putuskan berdasarkan skor aturan saja.
    final risk = score >= 0.5 ? RiskLevel.medium : RiskLevel.low;
    return build(
      risk: risk,
      threat: risk == RiskLevel.low ? ThreatCodes.none : rule.threatCode,
      confidence: score,
      summary: risk == RiskLevel.low
          ? 'Tidak ditemukan indikasi kuat manipulasi.'
          : '${_ruleSummary(rule)} (analisis AI tidak tersedia).',
      layer: 3,
      entities: rule.entities,
    );
  }

  static String _ruleSummary(RuleResult rule) {
    final label = switch (rule.threatCode) {
      ThreatCodes.apkScam => 'Pola penipuan berkas APK',
      ThreatCodes.financialPhishing => 'Pola phishing finansial',
      ThreatCodes.impersonation => 'Pola penyamaran pihak berwenang/kerabat',
      ThreatCodes.suspiciousLink => 'Tautan mencurigakan',
      ThreatCodes.socialEngineering => 'Pola rekayasa sosial',
      _ => 'Pesan mencurigakan',
    };
    if (rule.signals.isEmpty) return '$label.';
    return '$label: ${rule.signals.take(3).join(', ')}.';
  }

  static String _newId() =>
      'sc_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}
