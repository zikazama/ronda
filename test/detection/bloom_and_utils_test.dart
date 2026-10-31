import 'package:flutter_test/flutter_test.dart';
import 'package:ronda/core/detection/bloom_filter.dart';
import 'package:ronda/core/detection/number_utils.dart';
import 'package:ronda/core/detection/privacy_sanitizer.dart';

void main() {
  group('BloomFilter', () {
    test('tidak ada false negative dan false positive terkendali', () {
      final bloom = BloomFilter.forCapacity(10000, falsePositiveRate: 0.001);
      for (var i = 0; i < 10000; i++) {
        bloom.add('+62812${i.toString().padLeft(8, '0')}');
      }
      for (var i = 0; i < 10000; i += 97) {
        expect(
          bloom.mightContain('+62812${i.toString().padLeft(8, '0')}'),
          isTrue,
        );
      }
      var falsePositives = 0;
      for (var i = 0; i < 5000; i++) {
        if (bloom.mightContain('+62899${i.toString().padLeft(8, '0')}')) {
          falsePositives++;
        }
      }
      expect(falsePositives / 5000, lessThan(0.01));
    });

    test('serialisasi base64 mempertahankan isi', () {
      final bloom = BloomFilter.forCapacity(100)..add('+628111');
      final restored = BloomFilter.fromBase64(bloom.toBase64());
      expect(restored.mightContain('+628111'), isTrue);
      expect(restored.mightContain('+628222'), isFalse);
    });
  });

  group('normalizeNumber / senderKey', () {
    test('menormalkan berbagai format Indonesia', () {
      expect(normalizeNumber('0812-9876-5432'), '+6281298765432');
      expect(normalizeNumber('+62 812 9876 5432'), '+6281298765432');
      expect(normalizeNumber('6281298765432'), '+6281298765432');
    });

    test('bukan nomor -> null, senderKey memakai slug nama', () {
      expect(normalizeNumber('Bank BRI'), isNull);
      expect(senderKey('Bank BRI'), 'name:bank_bri');
      expect(senderKey('0812 3456 7890'), '+6281234567890');
    });
  });

  group('sanitizeForAi', () {
    test('menyamarkan nomor, email, dan angka panjang', () {
      final out = sanitizeForAi(
        'Hubungi 081298765432 atau budi@mail.com, rek 1234567890123',
      );
      expect(out, isNot(contains('081298765432')));
      expect(out, isNot(contains('budi@mail.com')));
      expect(out, isNot(contains('1234567890123')));
      expect(out, contains('[NOMOR]'));
      expect(out, contains('[EMAIL]'));
    });

    test('memotong teks panjang', () {
      expect(
        sanitizeForAi('a' * 1000, maxLength: 50).length,
        lessThanOrEqualTo(51),
      );
    });
  });
}
