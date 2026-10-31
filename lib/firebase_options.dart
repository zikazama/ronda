// Konfigurasi Firebase proyek `ronda-kch-2026` (akun fauzi.fadman@gmail.com).
//
// Catatan: API key Firebase untuk klien BUKAN rahasia; keamanan data dijaga
// oleh `firestore.rules` (dan sebaiknya App Check sebelum rilis publik).
// Nilai 'REPLACE_ME' berarti Firebase belum diatur — aplikasi tetap berjalan
// dengan mode lokal (Lapis 1 & 3 saja).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak dikonfigurasi untuk platform ini.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDpzUnif0gfsErzfniCpjvbTCvu87y-GyU',
    appId: '1:8587085159:web:5d72e3a4090fcce6979bc2',
    messagingSenderId: '8587085159',
    projectId: 'ronda-kch-2026',
    authDomain: 'ronda-kch-2026.firebaseapp.com',
    storageBucket: 'ronda-kch-2026.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6ZtsVfI9LJmPCGELcYWbilMgA85a5AJU',
    appId: '1:8587085159:android:0b9c25810ef31206979bc2',
    messagingSenderId: '8587085159',
    projectId: 'ronda-kch-2026',
    storageBucket: 'ronda-kch-2026.firebasestorage.app',
  );
}
