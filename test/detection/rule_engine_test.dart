import 'package:flutter_test/flutter_test.dart';
import 'package:ronda/core/detection/rule_engine.dart';

void main() {
  const engine = RuleEngine();

  test('undangan pernikahan .apk dari proposal dinilai berbahaya', () {
    final r = engine.analyze(
      'UNDANGAN PERNIKAHAN digital.apk - Silahkan buka paket untuk melihat lokasi acara.',
    );
    expect(r.score, greaterThanOrEqualTo(RuleEngine.highThreshold));
    expect(r.threatCode, ThreatCodes.apkScam);
    expect(r.entities.fileExtension, '.apk');
  });

  test('surat tilang ETLE + APK dinilai berbahaya', () {
    final r = engine.analyze(
      'PENTING! Surat Tilang Elektronik ETLE No.882. Unduh file APK lampiran utk cek foto bukti.',
    );
    expect(r.score, greaterThanOrEqualTo(RuleEngine.highThreshold));
    expect(r.entities.fileExtension, '.apk');
  });

  test(
    'ekstrak nomor rekening dan hadiah menjadi kasus abu-abu atau lebih',
    () {
      final r = engine.analyze(
        'Selamat anda menang undian! tf 500rb ke rek BCA 1234567890 a/n Budi',
      );
      expect(r.entities.bankAccount, '1234567890');
      expect(r.score, greaterThanOrEqualTo(RuleEngine.lowThreshold));
    },
  );

  test('link pendek terdeteksi sebagai tautan mencurigakan', () {
    final r = engine.analyze('Cek foto kamu di https://bit.ly/3xYz');
    expect(r.entities.suspiciousUrl, contains('bit.ly'));
    expect(r.threatCode, ThreatCodes.suspiciousLink);
  });

  test('domain yang meniru brand dinilai penyamaran', () {
    final r = engine.analyze(
      'Verifikasi akun: https://bca-klik-aman.xyz/login',
    );
    expect(r.threatCode, ThreatCodes.impersonation);
    expect(r.score, greaterThanOrEqualTo(0.6));
  });

  test('domain resmi brand tidak dianggap meniru', () {
    final r = engine.analyze('Info resmi di https://www.bca.co.id/promo');
    expect(r.threatCode, isNot(ThreatCodes.impersonation));
  });

  test('percakapan akrab biasa dinilai aman', () {
    final r = engine.analyze('Bro jadi gak ntar malem makan bareng?');
    expect(r.score, lessThan(RuleEngine.lowThreshold));
  });

  test('teks kosong aman', () {
    expect(engine.analyze('   ').score, 0);
  });
}
