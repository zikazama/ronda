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
    scan/      model domain, provider, data contoh
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

## Status

UI memakai data contoh (`MockScanData`). Belum diimplementasikan:

- Kotlin `NotificationListenerService`, overlay `SYSTEM_ALERT_WINDOW`, audio/haptic
  (kontrak channel ada di `core/platform/native_bridge.dart`)
- Klien API NestJS `POST /api/v1/notifications/scan`
- Offline filter SQLite + Bloom Filter
- Data peta masih contoh (`MockHeatmapData`); belum terhubung ke agregat backend
