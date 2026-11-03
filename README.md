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
3. **App Check** → daftarkan aplikasi Android dengan **Play Integrity** (butuh SHA-256
   kunci rilis) → baru setelah itu pilih *Enforce* untuk Firestore & AI Logic.
   Kode klien sudah mengaktifkan App Check (provider *debug* di build debug;
   daftarkan debug token dari logcat bila ingin menguji dengan enforcement aktif).
   Di web App Check dilewati (butuh reCAPTCHA site key).

Tanpa langkah itu aplikasi tetap jalan memakai Lapis 1 & 3 saja.

## Build Android

Butuh JDK 17 dan Android SDK (platform 36 & 37, build-tools 36.0.0).

```bash
flutter build apk --debug      # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release    # R8 aktif; ditandatangani keystore rilis bila android/key.properties ada
```

Catatan: `compileSdk = 37` karena `permission_handler_android` menuntutnya; AGP 9.1
baru merekomendasikan sampai 36 (peringatan disenyapkan di `gradle.properties`).
Keystore rilis: `android/key.properties` (di-gitignore) menunjuk ke file `.jks` di luar repo
(`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Tanpa file itu build rilis jatuh ke kunci
debug. **Cadangkan file `.jks` dan kata sandinya** — hilang berarti tidak bisa merilis pembaruan
dengan identitas yang sama. Daftarkan SHA-256-nya di Firebase bila memakai App Check Play Integrity.

Data peta awal (sintetis, 42 sel H3 di Jakarta): `cd tool && npm install && node seed_threat_cells.mjs`
(`--dry-run` untuk pratinjau, `--remove` untuk menghapus). Memakai akun gcloud `fauzi.fadman@gmail.com`.
Kebijakan privasi publik: `https://ronda-kch-2026.web.app/privacy` (sumber `hosting/`, deploy dengan
`firebase deploy --only hosting`).

Dokumen pendukung: `docs/DEVICE_TEST_CHECKLIST.md` (uji HP & instal manual) dan
`docs/PRIVACY_POLICY.md` (draf kebijakan privasi untuk Play Store).

Setelah terpasang: Profil → aktifkan **Akses notifikasi** dan **Tampil di atas aplikasi lain**.

## Status & keterbatasan

Terverifikasi di mesin pengembang:

- `flutter analyze` bersih, 33 tes lulus, `flutter build web` dan `flutter build apk`
  (debug & release) berhasil; kelas Kotlin dan manifest ada di APK.
- Backend sungguhan: anonymous sign-in, Gemini (`gemini-3.5-flash-lite`) lewat AI Logic,
  dan aturan Firestore (laporan unik diterima, duplikat ditolak, sel peta tidak bisa
  digelembungkan tanpa laporan, `user_reports` tidak bisa dibaca).

Belum terverifikasi (butuh perangkat Android nyata):

- Perilaku runtime Kotlin: pembacaan notifikasi WhatsApp/SMS, overlay, alarm/getar,
  pengecekan kontak, engine yang tetap hidup saat aplikasi ditutup.
- App Check dengan enforcement aktif.

Keterbatasan desain:

- Tingkat MEDIUM hanya masuk riwayat (tanpa overlay). "Blokir" bersifat level
  aplikasi, bukan pemblokiran nomor di tingkat OS.
- Pengguna anonim bisa dibuat berulang → App Check wajib untuk produksi.
- Build memperingatkan plugin Firebase masih memakai Kotlin Gradle Plugin (tidak fatal sekarang).