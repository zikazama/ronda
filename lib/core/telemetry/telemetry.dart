import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Pelaporan kerusakan & jejak diagnosis lewat Firebase Crashlytics.
///
/// ATURAN PRIVASI (sesuai kebijakan privasi): yang dicatat hanya METADATA
/// keputusan — aplikasi sumber, lapis, tingkat risiko, status izin, kegagalan
/// sambungan. TIDAK PERNAH isi pesan, nomor/nama pengirim, atau lokasi.
///
/// Semua fungsi aman dipanggil kapan saja: tidak berbuat apa-apa bila belum
/// aktif (web, tes, atau Firebase gagal).
abstract final class Telemetry {
  static bool _enabled = false;
  static bool _overlayFailureReported = false;

  static bool get enabled => _enabled;

  /// Dipanggil sekali dari `main()`. Menginisialisasi Firebase (tidak butuh
  /// jaringan) lalu memasang penangkap error Flutter dan Dart.
  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(true);

      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
      _enabled = true;
      crashlytics.log('telemetry aktif');
    } on Object catch (e) {
      debugPrint('Telemetry tidak aktif: $e');
    }
  }

  /// Baris jejak yang ikut terkirim bersama laporan berikutnya.
  static void log(String message) {
    if (!_enabled) return;
    try {
      FirebaseCrashlytics.instance.log(message);
    } on Object {
      // Telemetri tidak boleh mengganggu fitur utama.
    }
  }

  /// Penanda keadaan terkini (mis. izin overlay), tampil di tiap laporan.
  static void key(String name, Object value) {
    if (!_enabled) return;
    try {
      FirebaseCrashlytics.instance.setCustomKey(name, value);
    } on Object {
      // abaikan
    }
  }

  /// Masalah yang tidak membuat aplikasi crash tetapi perlu diketahui
  /// (mis. gagal terhubung ke Firebase).
  static void nonFatal(Object error, StackTrace? stack, {String? reason}) {
    if (!_enabled) return;
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    } on Object {
      // abaikan
    }
  }

  /// Peringatan gagal tampil. Dilaporkan sekali per proses agar tidak
  /// membanjiri; kejadian berikutnya cukup tercatat sebagai log.
  static void overlayFailed() {
    key('overlay_tampil', false);
    log('overlay GAGAL tampil (izin overlay belum aktif atau ditolak sistem)');
    if (_overlayFailureReported) return;
    _overlayFailureReported = true;
    nonFatal(
      StateError('Overlay peringatan gagal tampil'),
      StackTrace.current,
      reason: 'izin overlay belum aktif atau ditolak sistem',
    );
  }
}
