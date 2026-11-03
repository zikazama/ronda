/// Menormalkan teks pesan sebelum dicocokkan dengan aturan, supaya trik
/// penyamaran yang umum di pesan penipuan tidak lolos:
///
/// * huruf lebar penuh / matematis ("ｈａｄｉａｈ", "𝐡𝐚𝐝𝐢𝐚𝐡")
/// * karakter tak terlihat (zero-width) yang menyelip di tengah kata
/// * aksen ("hádiah")
/// * leetspeak di dalam kata ("h4d14h", "b3rh4d14h", "p@ket")
/// * huruf dipisah ("h a d i a h", "H.A.D.I.A.H", "k-l-i-k")
/// * huruf diulang ("hadiaaah", "gratiiis")
///
/// Hasilnya HANYA untuk pencocokan kata kunci. URL, nomor rekening, dan teks
/// yang ditampilkan/dikirim tetap memakai teks asli.
String normalizeForMatching(String input) {
  if (input.isEmpty) return input;

  final out = StringBuffer();
  for (final rune in input.runes) {
    final c = _foldRune(rune);
    if (c != null) out.writeCharCode(c);
  }
  var s = out.toString().toLowerCase();

  s = _collapseSpacedLetters(s);
  s = _decodeLeet(s);
  s = _collapseRepeats(s);
  return s.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
}

/// `null` = buang karakter (zero-width).
int? _foldRune(int r) {
  // Karakter tak terlihat.
  if ((r >= 0x200B && r <= 0x200F) ||
      r == 0x2060 ||
      r == 0xFEFF ||
      r == 0x00AD ||
      (r >= 0x202A && r <= 0x202E)) {
    return null;
  }
  // Lebar penuh (！ … ～) -> ASCII.
  if (r >= 0xFF01 && r <= 0xFF5E) return r - 0xFEE0;
  // Alfanumerik matematis (𝐀 … 𝟿): 13 gaya huruf, lalu 5 gaya angka.
  if (r >= 0x1D400 && r <= 0x1D6A3) {
    final i = (r - 0x1D400) % 52;
    return i < 26 ? 0x41 + i : 0x61 + (i - 26);
  }
  if (r >= 0x1D7CE && r <= 0x1D7FF) return 0x30 + (r - 0x1D7CE) % 10;
  // Aksen Latin yang lazim.
  final plain = _accents[r];
  if (plain != null) return plain.codeUnitAt(0);
  return r;
}

const _accents = <int, String>{
  0xE0: 'a', 0xE1: 'a', 0xE2: 'a', 0xE3: 'a', 0xE4: 'a', 0xE5: 'a',
  0xE8: 'e', 0xE9: 'e', 0xEA: 'e', 0xEB: 'e',
  0xEC: 'i', 0xED: 'i', 0xEE: 'i', 0xEF: 'i',
  0xF2: 'o', 0xF3: 'o', 0xF4: 'o', 0xF5: 'o', 0xF6: 'o',
  0xF9: 'u', 0xFA: 'u', 0xFB: 'u', 0xFC: 'u',
  0xC0: 'a', 0xC1: 'a', 0xC2: 'a', 0xC3: 'a', 0xC4: 'a',
  0xC8: 'e', 0xC9: 'e', 0xCA: 'e', 0xCB: 'e',
  0xCC: 'i', 0xCD: 'i', 0xCE: 'i', 0xCF: 'i',
  0xD2: 'o', 0xD3: 'o', 0xD4: 'o', 0xD5: 'o', 0xD6: 'o',
  0xD9: 'u', 0xDA: 'u', 0xDB: 'u', 0xDC: 'u',
};

/// "h a d i a h" / "H.A.D.I.A.H" / "k-l-i-k" -> "hadiah" / "klik".
/// Hanya untuk rangkaian >= 3 huruf tunggal ("o.t.p", "a p k"); pasangan
/// seperti "A B" dibiarkan.
final _spaced = RegExp(r'(?<![a-z0-9])(?:[a-z][ .\-_*]){2,}[a-z](?![a-z0-9])');

String _collapseSpacedLetters(String s) =>
    s.replaceAllMapped(_spaced, (m) => m[0]!.replaceAll(RegExp(r'[ .\-_*]'), ''));

const _leet = {
  '4': 'a',
  '3': 'e',
  '1': 'i',
  '0': 'o',
  '5': 's',
  '7': 't',
  '@': 'a',
  r'$': 's',
};

/// Token berisi huruf bercampur angka/simbol pengganti huruf ("h4d14h",
/// "k0d3", "v3r1f1k4s1"). Dianggap leetspeak bila huruf >= 2 dan angka/simbol
/// tidak lebih banyak dari huruf. Dengan syarat itu "otp123456", "bca2024",
/// "250rb", dan "rp50000" (angka lebih banyak) tidak tersentuh.
final _token = RegExp(r'[a-z0-9@$]+');

String _decodeLeet(String s) => s.replaceAllMapped(_token, (m) {
  final w = m[0]!;
  var letters = 0;
  var marks = 0;
  for (final ch in w.split('')) {
    if (RegExp(r'[a-z]').hasMatch(ch)) {
      letters++;
    } else {
      marks++;
    }
  }
  if (marks == 0 || letters < 2 || marks > letters) return w;
  final b = StringBuffer();
  for (final ch in w.split('')) {
    b.write(_leet[ch] ?? ch);
  }
  return b.toString();
});

/// "hadiaaah" -> "hadiah". Tiga huruf sama berturut-turut hampir tidak pernah
/// ada dalam bahasa Indonesia baku.
String _collapseRepeats(String s) =>
    s.replaceAllMapped(RegExp(r'([a-z])\1{2,}'), (m) => m[1]!);
