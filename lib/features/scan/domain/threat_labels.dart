import '../../../core/detection/rule_engine.dart';
import 'scan_result.dart';

/// Bahasa yang dipahami pengguna untuk hasil deteksi (bukan kode internal).
extension ThreatLabels on ScanResult {
  String get threatTitle => switch (threatType) {
    ThreatCodes.apkScam => 'Modus berkas APK palsu',
    ThreatCodes.financialPhishing => 'Phishing finansial',
    ThreatCodes.impersonation => 'Penyamaran pihak tepercaya',
    ThreatCodes.suspiciousLink => 'Tautan berbahaya',
    ThreatCodes.knownScammer => 'Nomor penipu dikenal',
    ThreatCodes.socialEngineering => 'Rekayasa sosial',
    _ => riskLevel == RiskLevel.low ? 'Pesan aman' : 'Pesan mencurigakan',
  };

  /// Langkah yang sebaiknya dilakukan pengguna, paling penting dulu.
  List<String> get advice => switch (threatType) {
    ThreatCodes.apkScam => const [
      'Jangan buka atau pasang file APK dari pesan ini.',
      'Hapus pesannya. Bank dan kurir tidak mengirim aplikasi lewat chat.',
    ],
    ThreatCodes.financialPhishing => const [
      'Jangan klik tautan atau isi data rekening dan kartu.',
      'Jangan bagikan kode OTP atau PIN kepada siapa pun.',
      'Hubungi bank lewat nomor resmi di kartu atau aplikasinya.',
    ],
    ThreatCodes.impersonation => const [
      'Cek langsung ke pihak yang disebut, lewat nomor resminya.',
      'Jangan transfer uang atas permintaan lewat pesan.',
    ],
    ThreatCodes.suspiciousLink => const [
      'Jangan klik tautan di pesan ini.',
      'Jika perlu, buka situs resminya langsung dari browser.',
    ],
    ThreatCodes.knownScammer => const [
      'Nomor ini sudah dilaporkan sebagai penipu. Jangan membalas.',
    ],
    _ => const [
      'Jangan membalas atau mengirim uang dan data pribadi.',
      'Pastikan dulu lewat kontak resmi pengirimnya.',
    ],
  };
}
