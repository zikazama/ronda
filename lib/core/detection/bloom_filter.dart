import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Bloom filter ringkas untuk pencocokan nomor penipu secara luring.
///
/// Memakai double hashing dari SHA-256 dengan nilai 32-bit, sehingga hasilnya
/// identik di Android maupun web.
class BloomFilter {
  BloomFilter._(this.bitCount, this.hashCount, this._bits);

  /// Ukuran dihitung dari [capacity] elemen dan target false-positive
  /// [falsePositiveRate] (default 1%).
  factory BloomFilter.forCapacity(
    int capacity, {
    double falsePositiveRate = 0.01,
  }) {
    final n = math.max(capacity, 1);
    final m = math.max(
      64,
      (-n * math.log(falsePositiveRate) / (math.ln2 * math.ln2)).ceil(),
    );
    final k = math.max(1, (m / n * math.ln2).round());
    return BloomFilter._(m, k, Uint8List((m + 7) ~/ 8));
  }

  factory BloomFilter.fromBase64(String encoded) {
    final map = jsonDecode(encoded) as Map<String, dynamic>;
    return BloomFilter._(
      map['m'] as int,
      map['k'] as int,
      base64Decode(map['bits'] as String),
    );
  }

  final int bitCount;
  final int hashCount;
  final Uint8List _bits;

  void add(String value) {
    for (final index in _indexes(value)) {
      _bits[index >> 3] |= 1 << (index & 7);
    }
  }

  bool mightContain(String value) {
    for (final index in _indexes(value)) {
      if (_bits[index >> 3] & (1 << (index & 7)) == 0) return false;
    }
    return true;
  }

  String toBase64() =>
      jsonEncode({'m': bitCount, 'k': hashCount, 'bits': base64Encode(_bits)});

  Iterable<int> _indexes(String value) sync* {
    final digest = sha256.convert(utf8.encode(value)).bytes;
    final h1 = _u32(digest, 0);
    var h2 = _u32(digest, 4);
    if (h2.isEven) h2 += 1; // ganjil agar siklus penuh
    for (var i = 0; i < hashCount; i++) {
      yield (h1 + i * h2) % bitCount;
    }
  }

  // Aritmetika biasa (bukan shift 32-bit) supaya hasil sama di VM dan web.
  static int _u32(List<int> b, int o) =>
      b[o] * 16777216 + b[o + 1] * 65536 + b[o + 2] * 256 + b[o + 3];
}
