# Kebijakan Privasi RONDA

*Terakhir diperbarui: 3 November 2026. Draf — tinjau ulang dan isi kontak sebelum dipublikasikan.*

RONDA (Radar & Overlay Notifikasi Deteksi Ancaman) membantu pengguna Android mengenali
penipuan rekayasa sosial, phishing, dan file APK berbahaya pada pesan masuk.

## Data yang diproses di perangkat Anda

| Data | Tujuan | Disimpan? |
|---|---|---|
| Teks notifikasi SMS/WhatsApp/Telegram dan aplikasi pesan lain (lewat izin Akses Notifikasi) | Mendeteksi pesan penipuan | **Tidak.** Isi pesan tidak disimpan. Riwayat hanya berisi metadata dan ringkasan hasil analisis. |
| Pencocokan pengirim dengan Kontak (izin opsional) | Melewati pesan dari kontak tersimpan | **Tidak.** Pencocokan dilakukan di perangkat; daftar kontak tidak dikirim ke mana pun. |
| Lokasi kasar (izin opsional) | Menentukan sel wilayah untuk peta ancaman | Hanya sel wilayah H3 (±0,7 km²) yang dikirim, bukan koordinat. |

## Data yang dikirim ke server

1. **Analisis AI (Gemini, lewat Firebase AI Logic)** — hanya untuk pesan yang tidak bisa dipastikan
   oleh aturan lokal. Sebelum dikirim, nomor telepon, email, dan deret angka panjang diganti
   `[NOMOR]`, `[EMAIL]`, `[ANGKA]`, dan teks dipotong maksimal 600 karakter.
2. **Laporan komunitas** — saat Anda menekan "Blokir Nomor": nomor pengirim yang dilaporkan,
   jenis ancaman, platform, ringkasan singkat, sel wilayah H3 (jika izin lokasi diberikan),
   dan ID pengguna anonim.
3. **Pencarian reputasi nomor** — nomor pengirim dicari pada basis data komunitas untuk
   mengetahui apakah sudah dilaporkan pengguna lain.

Seluruh penyimpanan memakai Google Firebase (Firestore, Authentication anonim, App Check).
Anda tidak perlu membuat akun; identitas Anda hanya ID anonim acak.

## Yang tidak kami lakukan
- Tidak menjual atau membagikan data untuk iklan.
- Tidak menyimpan isi pesan Anda.
- Tidak membaca pesan dari kontak tersimpan.
- Tidak mengumpulkan nama, email, atau nomor telepon Anda sendiri.

## Hak dan kontrol Anda
- Cabut izin kapan saja di Pengaturan Android (Akses Notifikasi, Kontak, Lokasi, Tampil di
  Atas Aplikasi Lain). Aplikasi tetap terbuka, hanya perlindungan yang berhenti.
- Menghapus data aplikasi menghapus riwayat dan daftar blokir lokal serta ID anonim Anda.
- Laporan komunitas bersifat agregat dan tidak dapat dibaca ulang oleh klien; permintaan
  penghapusan laporan: hubungi kontak di bawah.

## Kontak
Pertanyaan atau permintaan terkait data pribadi (UU No. 27 Tahun 2022 tentang Pelindungan Data
Pribadi): **[isi alamat email kontak]**
