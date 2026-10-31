abstract final class AppConstants {
  static const appName = 'RONDA';
  static const tagline = 'Radar & Overlay Notifikasi Deteksi Ancaman';

  /// Nama channel native (Kotlin) <-> Flutter.
  static const packageId = 'id.web.ronda';
  static const notificationEventChannel = '$packageId/notifications';
  static const overlayMethodChannel = '$packageId/overlay';

  /// Model Gemini via Firebase AI Logic (Gemini Developer API, tersedia di
  /// paket gratis Spark). Ganti bila model dipensiunkan.
  static const geminiModel = 'gemini-3.5-flash-lite';
  static const aiTimeout = Duration(seconds: 8);

  /// Target latensi pipeline deteksi (ms), sesuai spesifikasi.
  static const targetLatencyMs = 350;

  /// Pesan identik dari pengirim yang sama diabaikan dalam jendela ini
  /// (WhatsApp sering memperbarui notifikasi yang sama).
  static const dedupeWindow = Duration(seconds: 30);

  /// Jumlah maksimum riwayat deteksi yang disimpan.
  static const historyLimit = 100;

  /// Minimal laporan komunitas agar nomor dianggap berbahaya (Lapis 2).
  static const communityHighThreshold = 3;

  /// Poin reputasi per laporan yang dikirim.
  static const pointsPerReport = 25;
}
