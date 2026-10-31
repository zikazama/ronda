import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

/// Layanan Firebase yang siap dipakai (sudah login anonim).
class CloudServices {
  const CloudServices({
    required this.app,
    required this.firestore,
    required this.uid,
  });

  final FirebaseApp app;
  final FirebaseFirestore firestore;
  final String uid;
}

/// Pintu tunggal ke Firebase. Aman dipanggil kapan saja: bila Firebase belum
/// dikonfigurasi, luring, atau gagal, hasilnya `null` dan pemanggil jatuh ke
/// mode lokal. Inisialisasi dicoba ulang berkala saat koneksi pulih.
class CloudGateway {
  CloudGateway({this._options, this.retryAfter = const Duration(seconds: 60)});

  final FirebaseOptions? _options;
  final Duration retryAfter;

  CloudServices? _services;
  Future<CloudServices?>? _inFlight;
  DateTime? _lastAttempt;

  FirebaseOptions get _resolved =>
      _options ?? DefaultFirebaseOptions.currentPlatform;

  /// `true` bila nilai konfigurasi sudah diisi (bukan placeholder).
  bool get isConfigured {
    try {
      return !_resolved.apiKey.startsWith('REPLACE_ME');
    } on UnsupportedError {
      return false;
    }
  }

  Future<CloudServices?> services() {
    if (_services != null) return Future.value(_services);
    if (!isConfigured) return Future.value(null);

    final last = _lastAttempt;
    if (_inFlight == null &&
        (last == null || DateTime.now().difference(last) >= retryAfter)) {
      _lastAttempt = DateTime.now();
      _inFlight = _init().whenComplete(() => _inFlight = null);
    }
    return _inFlight ?? Future.value(null);
  }

  /// Seperti [services], tapi menyerah cepat. Dipakai di jalur deteksi agar
  /// inisialisasi/login yang lambat tidak menahan peringatan ke pengguna.
  Future<CloudServices?> servicesQuick({
    Duration wait = const Duration(seconds: 2),
  }) => services().timeout(wait, onTimeout: () => null);

  Future<CloudServices?> _init() async {
    try {
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp(options: _resolved)
          : Firebase.app();
      final auth = FirebaseAuth.instanceFor(app: app);
      final user =
          auth.currentUser ??
          (await auth.signInAnonymously().timeout(const Duration(seconds: 10)))
              .user;
      if (user == null) return null;
      return _services = CloudServices(
        app: app,
        firestore: FirebaseFirestore.instanceFor(app: app),
        uid: user.uid,
      );
    } catch (e) {
      debugPrint('Firebase tidak tersedia, memakai mode lokal: $e');
      return null;
    }
  }
}

final cloudGatewayProvider = Provider<CloudGateway>((ref) => CloudGateway());
