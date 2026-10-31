import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../cloud/cloud_gateway.dart';
import '../constants/app_constants.dart';
import '../../features/scan/domain/scan_result.dart';
import 'rule_engine.dart';

class CognitiveVerdict {
  const CognitiveVerdict({
    required this.riskLevel,
    required this.threatCode,
    required this.confidence,
    required this.summary,
  });

  final RiskLevel riskLevel;
  final String threatCode;
  final double confidence;
  final String summary;
}

/// Lapis 4 — analisis manipulasi psikologis & bahasa lokal oleh AI.
abstract interface class CognitiveAnalyzer {
  /// `null` bila AI tak tersedia (luring / belum dikonfigurasi / gagal).
  /// [text] harus sudah disanitasi.
  Future<CognitiveVerdict?> analyze({
    required MessagePlatform platform,
    required String text,
    required List<String> ruleSignals,
  });
}

/// Prompt "Nusantara NLP": few-shot untuk slang dan bahasa daerah.
const nusantaraSystemPrompt = '''
Kamu adalah RONDA, analis keamanan siber untuk melindungi masyarakat Indonesia dari penipuan pesan (SMS, WhatsApp, Telegram, dll).
Tugasmu: menilai satu pesan dari pengirim yang TIDAK ada di kontak pengguna.

Perhatikan manipulasi psikologis: rasa takut palsu, desakan waktu, iming-iming hadiah/untung, penyamaran (polisi, bank, kurir, keluarga), permintaan OTP/PIN, file .apk, link pendek, dan permintaan transfer.
Pahami slang dan bahasa daerah: tf/trf (transfer), brg (barang), gaskeun, cuan, wd, depo; Jawa (sampeyan, iki, ojo, mas), Sunda (kang, mangga, pikeun, can nepi), Batak (lae, kali, ku). Pesan akrab yang wajar BUKAN penipuan.
Teks sudah disamarkan: [NOMOR], [ANGKA], [EMAIL] adalah data pribadi yang disembunyikan.

Jawab HANYA JSON valid dengan kunci:
{"risk_level":"LOW|MEDIUM|HIGH","threat_type":"NONE|APK_SCAM|FINANCIAL_PHISHING|IMPERSONATION|SUSPICIOUS_LINK|SOCIAL_ENGINEERING","confidence_score":0.0-1.0,"ai_summary":"satu kalimat Bahasa Indonesia, maksimal 140 karakter"}

Contoh:
Pesan: "tf 50rb dulu bro buat modal, besok gw balikin 2x lipat gaskeun"
{"risk_level":"HIGH","threat_type":"FINANCIAL_PHISHING","confidence_score":0.9,"ai_summary":"Janji uang kembali berlipat setelah transfer: pola penipuan investasi."}

Pesan: "Mas, sampeyan menang undian iki, klik link ning ngisor ojo telat ya"
{"risk_level":"HIGH","threat_type":"SOCIAL_ENGINEERING","confidence_score":0.88,"ai_summary":"Iming-iming undian dengan tautan dan desakan waktu."}

Pesan: "Kang, ieu aya paket can nepi, mangga buka file na pikeun ningali resi"
{"risk_level":"HIGH","threat_type":"APK_SCAM","confidence_score":0.9,"ai_summary":"Modus paket palsu meminta membuka file lampiran."}

Pesan: "Lae, tolong transfer dulu ke rekening ku, mendesak kali, nanti kutambah"
{"risk_level":"MEDIUM","threat_type":"IMPERSONATION","confidence_score":0.6,"ai_summary":"Permintaan transfer mendesak dari pengirim tak dikenal."}

Pesan: "Bro jadi gak ntar malem makan bareng? Gw tf besok ya patungan kemarin"
{"risk_level":"LOW","threat_type":"NONE","confidence_score":0.85,"ai_summary":"Percakapan akrab biasa tanpa indikasi manipulasi."}
''';

class GeminiAnalyzer implements CognitiveAnalyzer {
  GeminiAnalyzer(this._gateway);

  final CloudGateway _gateway;

  @override
  Future<CognitiveVerdict?> analyze({
    required MessagePlatform platform,
    required String text,
    required List<String> ruleSignals,
  }) async {
    final cloud = await _gateway.servicesQuick();
    if (cloud == null) return null;

    final model = FirebaseAI.googleAI(app: cloud.app).generativeModel(
      model: AppConstants.geminiModel,
      systemInstruction: Content.system(nusantaraSystemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
        maxOutputTokens: 200,
      ),
    );

    final hints = ruleSignals.isEmpty
        ? ''
        : '\nSinyal lokal terdeteksi: ${ruleSignals.join(', ')}.';
    final response = await model
        .generateContent([
          Content.text('Platform: ${platform.label}$hints\nPesan: "$text"'),
        ])
        .timeout(AppConstants.aiTimeout);

    return parseVerdict(response.text);
  }

  /// Dipisah agar bisa diuji tanpa jaringan.
  @visibleForTesting
  static CognitiveVerdict? parseVerdict(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final cleaned = raw
          .replaceAll(RegExp(r'^```(?:json)?', multiLine: true), '')
          .replaceAll('```', '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final threat = json['threat_type'] as String? ?? ThreatCodes.none;
      return CognitiveVerdict(
        riskLevel: RiskLevel.parse(json['risk_level'] as String? ?? 'LOW'),
        threatCode: threat,
        confidence: ((json['confidence_score'] as num?)?.toDouble() ?? 0.5)
            .clamp(0.0, 1.0),
        summary: (json['ai_summary'] as String? ?? '').trim(),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
