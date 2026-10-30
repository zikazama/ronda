abstract final class AppConstants {
  static const appName = 'RONDA';
  static const tagline = 'Radar & Overlay Notifikasi Deteksi Ancaman';

  /// Base URL backend NestJS. Ganti saat backend tersedia.
  static const apiBaseUrl = 'https://api.ronda.example/api/v1';
  static const scanEndpoint = '/notifications/scan';

  /// Nama channel native (Kotlin) <-> Flutter.
  static const packageId = 'id.web.ronda';
  static const notificationEventChannel = '$packageId/notifications';
  static const overlayMethodChannel = '$packageId/overlay';

  /// Target latensi pipeline deteksi (ms), sesuai spesifikasi.
  static const targetLatencyMs = 350;
}
