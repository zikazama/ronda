/// Menormalkan nomor telepon ke format `+62...`. Mengembalikan `null` bila
/// [raw] bukan nomor (mis. nama kontak atau nama layanan).
String? normalizeNumber(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[\s\-().]'), '');
  if (!RegExp(r'^\+?\d{8,15}$').hasMatch(cleaned)) return null;

  if (cleaned.startsWith('+')) return cleaned;
  if (cleaned.startsWith('62')) return '+$cleaned';
  if (cleaned.startsWith('0')) return '+62${cleaned.substring(1)}';
  return '+$cleaned';
}

/// Kunci stabil untuk pengirim: nomor ter-normalisasi, atau `name:<slug>`
/// untuk pengirim non-numerik (aman dipakai sebagai ID dokumen Firestore).
String senderKey(String sender) {
  final number = normalizeNumber(sender);
  if (number != null) return number;
  final slug = sender
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'name:${slug.isEmpty ? 'unknown' : slug}';
}
