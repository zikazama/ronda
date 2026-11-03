# Checklist uji perangkat (instal manual)

Bagian ini belum bisa diuji otomatis — jalankan di HP Android sungguhan, idealnya 2–3 merek
berbeda (mis. Samsung, Xiaomi/Redmi, Oppo/Vivo). Catat hasil per perangkat.

## Instal
1. Salin `build/app/outputs/flutter-apk/app-release.apk` ke HP, buka, izinkan "instal dari sumber ini".
2. Buka RONDA → tab **Profil** → aktifkan satu per satu: **Akses Notifikasi**, **Tampil di Atas
   Aplikasi Lain**, **Tanpa Batasan Baterai**, Kontak (opsional).
3. **Android 13+ dan opsi Akses Notifikasi abu-abu?** Itu *restricted settings* untuk APK
   instal manual: Info Aplikasi RONDA → ⋮ → **Izinkan setelan terbatas**, lalu ulangi langkah 2.
4. Xiaomi/Oppo/Vivo/Samsung: aktifkan juga **Mulai otomatis / Autostart** dan kunci RONDA di
   layar Recent (tidak bisa dideteksi aplikasi, harus manual).

## Skenario (centang per perangkat)
| # | Skenario | Hasil yang diharapkan |
|---|---|---|
| 1 | Kirim SMS/WA berisi tautan `.apk` dari nomor tak dikenal, RONDA **terbuka** | Overlay + alarm, masuk Riwayat |
| 2 | Sama, RONDA **ditutup dari Recent** | Tetap terdeteksi (engine hidup) |
| 3 | Sama, **layar mati/terkunci** | Overlay muncul saat layar dibuka atau alarm berbunyi |
| 4 | Sama, ponsel mode **getar/senyap** | Getar, tanpa suara |
| 5 | Pesan dari **kontak tersimpan** (izin kontak aktif) | Tidak dianalisis |
| 6 | Pesan biasa ("besok rapat jam 9") | Tidak ada overlay |
| 7 | Tombol **Blokir** di overlay | Nomor masuk blokir, poin bertambah, laporan terkirim (cek Firestore `spam_summaries`) |
| 8 | **Mode pesawat**, kirim pesan penipuan | Tetap terdeteksi oleh Lapis 1/3 (aturan lokal) |
| 9 | Biarkan HP idle ±1 jam lalu kirim pesan | Masih terdeteksi (listener tidak dimatikan sistem) |
| 10 | Reboot HP, jangan buka RONDA, kirim pesan | Masih terdeteksi |

Jika #2, #3, #9, atau #10 gagal: biasanya penghemat baterai/autostart OEM; ambil `adb logcat -s RondaListener`
dan sertakan merek + versi Android.

## Catatan App Check pada instal manual
Build rilis memakai Play Integrity. APK instal manual **tidak lolos** verifikasi itu, jadi App
Check gagal mengeluarkan token. Selama App Check **belum di-enforce** di konsol (kondisi saat ini),
Firestore dan Gemini tetap bisa dipakai. **Jangan enforce** sebelum aplikasi didistribusikan lewat
Google Play (internal testing cukup), atau semua perangkat instal manual akan kehilangan akses.
