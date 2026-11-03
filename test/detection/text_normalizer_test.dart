import 'package:flutter_test/flutter_test.dart';
import 'package:ronda/core/detection/rule_engine.dart';
import 'package:ronda/core/detection/text_normalizer.dart';

void main() {
  group('normalizeForMatching', () {
    test('leetspeak di dalam kata', () {
      expect(normalizeForMatching('h4d14h'), 'hadiah');
      expect(normalizeForMatching('SELAMAT anda m3n4ng'), 'selamat anda menang');
      expect(normalizeForMatching('p@ket anda'), 'paket anda');
    });

    test('huruf dipisah', () {
      expect(normalizeForMatching('h a d i a h'), 'hadiah');
      expect(normalizeForMatching('H.A.D.I.A.H besar'), 'hadiah besar');
      expect(normalizeForMatching('k-l-i-k link ini'), 'klik link ini');
    });

    test('huruf diulang dan karakter tak terlihat', () {
      expect(normalizeForMatching('hadiaaah'), 'hadiah');
      expect(normalizeForMatching('had​iah'), 'hadiah');
    });

    test('huruf lebar penuh, matematis, dan beraksen', () {
      expect(normalizeForMatching('ｈａｄｉａｈ'), 'hadiah');
      expect(normalizeForMatching('\u{1D421}\u{1D41A}\u{1D41D}\u{1D422}\u{1D41A}\u{1D421}'), 'hadiah');
      expect(normalizeForMatching('hádiah'), 'hadiah');
    });

    test('tidak merusak angka, OTP, tanggal, dan pesan biasa', () {
      expect(normalizeForMatching('Kode OTP 123456'), 'kode otp 123456');
      expect(normalizeForMatching('otp123456'), 'otp123456');
      expect(normalizeForMatching('Rapat 12-03-2026 jam 09.30'), 'rapat 12-03-2026 jam 09.30');
      expect(normalizeForMatching('Besok rapat jam 9 ya'), 'besok rapat jam 9 ya');
      // Pasangan huruf tunggal tidak digabung.
      expect(normalizeForMatching('Opsi A atau B'), 'opsi a atau b');
      expect(normalizeForMatching('Bayar 250rb ke bca2024'), 'bayar 250rb ke bca2024');
    });
  });

  group('RuleEngine dengan penyamaran', () {
    const engine = RuleEngine();

    test('hadiah yang disamarkan tetap terdeteksi', () {
      final plain = engine.analyze('Selamat anda menang hadiah, klaim sekarang');
      final obfuscated = engine.analyze('S3L4M4T anda m3n4ng h a d i a h, k l a i m sekarang');
      expect(plain.signals, contains('iming-iming hadiah'));
      expect(obfuscated.signals, contains('iming-iming hadiah'));
    });

    test('permintaan OTP yang disamarkan tetap terdeteksi', () {
      final r = engine.analyze('Mohon kirim k0d3 v3r1f1k4s1 dan O.T.P anda');
      expect(r.signals, contains('minta data rahasia'));
    });

    test('APK yang disamarkan tetap terdeteksi', () {
      final r = engine.analyze('Pasang file kurir . a p k sekarang');
      expect(r.signals, contains('file APK'));
    });

    test('pesan biasa tetap bersih', () {
      expect(engine.analyze('Besok rapat jam 9 ya, jangan lupa bawa laptop').score, 0);
      expect(engine.analyze('Transfer sudah masuk 250rb, makasih ya').score, lessThan(RuleEngine.lowThreshold));
    });
  });
}
