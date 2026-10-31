# RONDA — Radar & Overlay Notifikasi Deteksi Ancaman

Aplikasi Flutter untuk Kartika Cyber Hackathon 2026 (kategori Penangkalan).
Memantau notifikasi pesan secara real-time dan memperingatkan pengguna dari
penipuan rekayasa sosial, phishing, dan file `.apk` berbahaya.

## Menjalankan

```bash
flutter pub get
flutter run
flutter test
```

## Struktur

```
lib/
  core/        theme, router, constants, platform bridge, widget bersama
  features/
    home/      Ronda Siber (radar + aktivitas terkini)
    heatmap/   Peta sebaran ancaman (heksagon ala H3)
    history/   Riwayat deteksi
    analysis/  Analisis AI + alur pipeline 4 lapis
    profile/   Pahlawan Siber + izin perlindungan
    scan/      model domain + riwayat (tersimpan lokal)
    report/    laporan komunitas + poin reputasi
    shell/     navigasi bawah
```

## Peta

- Tile: OpenStreetMap lewat `flutter_map` (atribusi sudah ditampilkan).
  Server tile publik OSM hanya untuk pengembangan/demo; untuk produksi pakai
  penyedia tile sendiri ([kebijakan](https://operations.osmfoundation.org/policies/tiles)).
- Sebaran ancaman: sel heksagonal Uber H3 (resolusi 8) via `h3_flutter`.
  Abstraksi ada di `core/geo/geo_index.dart` (`GeoIndex`).
- Lokasi pengguna memakai izin **kasar** (`ACCESS_COARSE_LOCATION`) dan hanya
  dikonversi ke sel H3 untuk anonimisasi (`location_hex` pada API).
- Web: butuh `h3-js`, sudah disertakan di `web/index.html`.

## Arsitektur deteksi (tanpa backend sendiri)

Pipeline 4 lapis (`lib/core/detection/`), berhenti di lapis pertama yang yakin:

1. **Offline** — daftar blokir lokal + Bloom Filter (`threat_list_store.dart`).
2. **Komunitas** — Firestore `spam_summaries/{nomor}` (hanya bila ada koneksi).
3. **Aturan** — regex/heuristik Indonesia: `.apk`, tautan pendek, bank/OTP, dll.
4. **AI** — Gemini via Firebase AI Logic, hanya untuk kasus abu-abu; teks
   dibersihkan dulu (nomor/angka/email disamarkan). Gagal/luring → skor aturan.

Android (`android/app/src/main/kotlin/id/web/ronda/`): `NotificationListenerService`
membaca notifikasi (lewati kontak tersimpan) → EventChannel → Dart. Ancaman HIGH
memunculkan overlay + alarm (mode normal) atau getar (senyap). Engine Flutter
di-cache di `RondaApplication` sehingga deteksi jalan walau aplikasi ditutup.
Isi pesan **tidak pernah disimpan**; riwayat hanya menyimpan metadata & ringkasan.

## Firebase (paket gratis Spark)

Proyek: `ronda-kch-2026` (akun fauzi.fadman@gmail.com). Konfigurasi klien di
`lib/firebase_options.dart`. Tanpa Cloud Functions, integritas data dijaga oleh
`firestore.rules` (satu laporan per pengguna per nomor; agregat hanya +1 bersama
laporan). Deploy ulang aturan: `firebase deploy --only firestore`.

Langkah manual di konsol (tidak bisa lewat CLI):

1. Authentication → Sign-in method → aktifkan **Anonymous**.
2. Firebase AI Logic → Get started → **Gemini Developer API** (tier gratis).
3. (Sebelum rilis publik) aktifkan **App Check** (Play Integrity).

Tanpa langkah itu aplikasi tetap jalan memakai Lapis 1 & 3 saja.

## Status & keterbatasan

- Dart: `flutter analyze` bersih, 33 tes lulus.
- Kode Kotlin & build APK **belum diverifikasi** (mesin pengembang tanpa Android SDK/JDK).
  Uji di perangkat nyata sebelum demo.
- Nama model Gemini (`AppConstants.geminiModel`) perlu dicek ketersediaannya.
- Tingkat MEDIUM hanya masuk riwayat (tanpa overlay). "Blokir" bersifat level
  aplikasi, bukan pemblokiran nomor di tingkat OS.
- Pengguna anonim bisa dibuat berulang → App Check wajib untuk produksi.