import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/scan/application/scan_providers.dart';
import '../../features/scan/domain/scan_result.dart';
import '../constants/app_constants.dart';
import '../platform/native_bridge.dart';
import 'detection_providers.dart';
import 'rule_engine.dart';
import 'spam_directory.dart';
import 'threat_list_store.dart';

/// Menghubungkan notifikasi masuk -> pipeline deteksi -> riwayat -> overlay.
///
/// Dijalankan sekali saat `main()`, hidup selama proses aplikasi hidup
/// (engine Flutter di-cache di `RondaApplication`), sehingga proteksi tetap
/// aktif walau layar aplikasi ditutup.
class DetectionService {
  DetectionService(this._ref, {NativeBridge? bridge})
    : _bridge = bridge ?? NativeBridge.instance;

  final Ref _ref;
  final NativeBridge _bridge;

  StreamSubscription<IncomingNotification>? _notifSub;
  StreamSubscription<OverlayAction>? _actionSub;
  Timer? _syncTimer;
  final _recent = <String, DateTime>{};
  bool _syncing = false;

  void start() {
    _notifSub ??= _bridge.notifications.listen(
      (n) => unawaited(process(n)),
      onError: (Object e) => debugPrint('Stream notifikasi error: $e'),
    );
    _actionSub ??= _bridge.overlayActions.listen(_onOverlayAction);

    unawaited(syncCommunityList());
    _syncTimer ??= Timer.periodic(
      const Duration(hours: 1),
      (_) => unawaited(syncCommunityList()),
    );
  }

  void dispose() {
    _notifSub?.cancel();
    _actionSub?.cancel();
    _syncTimer?.cancel();
    _notifSub = _actionSub = null;
    _syncTimer = null;
  }

  /// Memproses satu notifikasi. Mengembalikan `null` bila duplikat atau
  /// pipeline gagal. [simulated] melewati penyaringan duplikat (uji/demo).
  Future<ScanResult?> process(
    IncomingNotification n, {
    bool simulated = false,
  }) async {
    if (!simulated && _isDuplicate(n)) return null;

    final ScanResult result;
    try {
      result = await _ref.read(detectionPipelineProvider).scan(n);
    } on Object catch (e, st) {
      debugPrint('Pipeline gagal: $e\n$st');
      return null;
    }

    await _ref.read(scannedCountProvider.notifier).increment();
    if (result.riskLevel == RiskLevel.low) return result; // tidak disimpan

    await _ref.read(scanHistoryProvider.notifier).add(result);

    if (result.showsOverlay) {
      await _bridge.showOverlay(
        scanId: result.scanId,
        sender: result.sender,
        platformLabel: result.platform.label,
        title: _titleFor(result),
        summary: result.aiSummary,
        confidencePercent: (result.confidenceScore * 100).round(),
        playAlarm: true,
      );
    }
    return result;
  }

  /// Menyegarkan Bloom Filter dari komunitas (maks. tiap 6 jam, hemat kuota
  /// baca Firestore paket gratis).
  Future<void> syncCommunityList({bool force = false}) async {
    if (_syncing) return;
    final store = _ref.read(threatListStoreProvider);
    if (!force && !store.needsSync) return;

    _syncing = true;
    try {
      final keys = await _ref.read(spamDirectoryProvider).topSpamKeys();
      if (keys.isNotEmpty) await store.replaceCommunityList(keys);
    } on SpamDirectoryUnavailable {
      // Luring / Firebase nonaktif: pakai daftar terakhir.
    } on Object catch (e) {
      debugPrint('Sinkron daftar komunitas gagal: $e');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _onOverlayAction(OverlayAction action) async {
    if (action.action != 'block') return;
    final scan = _ref
        .read(scanHistoryProvider)
        .where((e) => e.scanId == action.scanId)
        .firstOrNull;
    if (scan == null) return;
    await _ref.read(reportServiceProvider).report(scan);
  }

  bool _isDuplicate(IncomingNotification n) {
    final now = DateTime.now();
    _recent.removeWhere(
      (_, t) => now.difference(t) > AppConstants.dedupeWindow,
    );
    final key = '${n.sender}|${n.body}';
    if (_recent.containsKey(key)) return true;
    _recent[key] = now;
    return false;
  }

  static String _titleFor(ScanResult r) => switch (r.threatType) {
    ThreatCodes.apkScam => 'Modus berkas APK palsu',
    ThreatCodes.financialPhishing => 'Phishing finansial',
    ThreatCodes.impersonation => 'Penyamaran pihak tepercaya',
    ThreatCodes.suspiciousLink => 'Tautan berbahaya',
    ThreatCodes.knownScammer => 'Nomor penipu dikenal',
    _ => 'Pesan berbahaya',
  };
}

final detectionServiceProvider = Provider<DetectionService>((ref) {
  final service = DetectionService(ref);
  ref.onDispose(service.dispose);
  return service;
});
