/// Membersihkan teks sebelum meninggalkan perangkat (analisis AI).
///
/// Nomor telepon, email, dan deret angka panjang dimasking agar data pribadi
/// tidak ikut terkirim. Hanya konteks bahasa penipuan yang dipertahankan.
String sanitizeForAi(String text, {int maxLength = 600}) {
  var s = text;
  s = s.replaceAll(RegExp(r'[\w.+\-]+@[\w\-]+(\.[\w\-]+)+'), '[EMAIL]');
  s = s.replaceAll(
    RegExp(r'(?<!\d)(\+?62|0)[\s\-]?\d[\d\s\-]{7,13}\d'),
    '[NOMOR]',
  );
  s = s.replaceAll(RegExp(r'\d{8,}'), '[ANGKA]');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.length > maxLength) s = '${s.substring(0, maxLength)}…';
  return s;
}
