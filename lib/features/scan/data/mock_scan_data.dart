import '../domain/scan_result.dart';

/// Data contoh untuk purwarupa UI. Ganti dengan repository API NestJS.
abstract final class MockScanData {
  static List<ScanResult> recent() {
    final now = DateTime.now();
    return [
      ScanResult.fromJson(
        {
          'scan_id': 'sc_9a8b7c6d5e',
          'risk_level': 'HIGH',
          'threat_type': 'APK_SCAM',
          'confidence_score': 0.99,
          'ai_summary': 'Pesan berpola modus penipuan berkas APK berkedok undangan pernikahan.',
          'extracted_entities': {
            'bank_account': null,
            'file_extension': '.apk',
            'suspicious_url': null,
          },
          'action_required': 'SHOW_POPUP_ALERT_AND_SOUND',
        },
        platform: MessagePlatform.whatsapp,
        sender: '+6281298765432',
        scannedAt: now.subtract(const Duration(seconds: 20)),
      ),
      ScanResult.fromJson(
        {
          'scan_id': 'sc_7f8a91b2c',
          'risk_level': 'HIGH',
          'threat_type': 'APK_SCAM',
          'confidence_score': 0.98,
          'ai_summary': 'Pesan berisi taktik penipuan berkas APK berbahaya berkedok surat tilang.',
          'extracted_entities': {
            'bank_account': null,
            'file_extension': '.apk',
            'suspicious_url': null,
          },
          'action_required': 'SHOW_POPUP_ALERT_AND_SOUND',
        },
        platform: MessagePlatform.sms,
        sender: '+6281234567890',
        scannedAt: now.subtract(const Duration(minutes: 2)),
      ),
      ScanResult.fromJson(
        {
          'scan_id': 'sc_3c2d1e0f9',
          'risk_level': 'MEDIUM',
          'threat_type': 'FINANCIAL_PHISHING',
          'confidence_score': 0.74,
          'ai_summary': 'Permintaan transfer mendesak ke rekening yang belum terverifikasi.',
          'extracted_entities': {
            'bank_account': '1234567890',
            'file_extension': null,
            'suspicious_url': null,
          },
          'action_required': 'SHOW_NOTIFICATION_WARNING',
        },
        platform: MessagePlatform.telegram,
        sender: '+6285512340099',
        scannedAt: now.subtract(const Duration(minutes: 8)),
      ),
      ScanResult.fromJson(
        {
          'scan_id': 'sc_1b2a3c4d5',
          'risk_level': 'LOW',
          'threat_type': 'NONE',
          'confidence_score': 0.91,
          'ai_summary':
              'Tidak ditemukan indikasi manipulasi atau tautan berbahaya.',
          'extracted_entities': {
            'bank_account': null,
            'file_extension': null,
            'suspicious_url': null,
          },
          'action_required': 'NONE',
        },
        platform: MessagePlatform.line,
        sender: 'LINE Official',
        scannedAt: now.subtract(const Duration(minutes: 25)),
      ),
    ];
  }
}
