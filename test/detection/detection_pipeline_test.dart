import 'package:flutter_test/flutter_test.dart';
import 'package:ronda/core/detection/cognitive_analyzer.dart';
import 'package:ronda/core/detection/detection_pipeline.dart';
import 'package:ronda/core/detection/rule_engine.dart';
import 'package:ronda/core/detection/spam_directory.dart';
import 'package:ronda/core/detection/threat_list_store.dart';
import 'package:ronda/core/platform/native_bridge.dart';
import 'package:ronda/features/scan/domain/scan_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDirectory implements SpamDirectory {
  _FakeDirectory({this.entries = const {}, this.unavailable = false});

  final Map<String, SpamEntry> entries;
  final bool unavailable;
  int lookups = 0;

  @override
  Future<SpamEntry?> lookup(String key) async {
    lookups++;
    if (unavailable) throw const SpamDirectoryUnavailable();
    return entries[key];
  }

  @override
  Future<List<String>> topSpamKeys({int limit = 500}) async => const [];
}

class _FakeAnalyzer implements CognitiveAnalyzer {
  _FakeAnalyzer([this.verdict]);

  final CognitiveVerdict? verdict;
  int calls = 0;
  String? lastText;

  @override
  Future<CognitiveVerdict?> analyze({
    required MessagePlatform platform,
    required String text,
    required List<String> ruleSignals,
  }) async {
    calls++;
    lastText = text;
    return verdict;
  }
}

IncomingNotification _msg(String body, {String sender = '+6281298765432'}) =>
    IncomingNotification(
      packageName: 'com.whatsapp',
      sender: sender,
      body: body,
      timestamp: 0,
    );

Future<(DetectionPipeline, ThreatListStore, _FakeDirectory, _FakeAnalyzer)>
_build({_FakeDirectory? directory, _FakeAnalyzer? analyzer}) async {
  SharedPreferences.setMockInitialValues({});
  final store = ThreatListStore(await SharedPreferences.getInstance());
  final dir = directory ?? _FakeDirectory();
  final ai = analyzer ?? _FakeAnalyzer();
  return (
    DetectionPipeline(store: store, directory: dir, analyzer: ai),
    store,
    dir,
    ai,
  );
}

void main() {
  test('Lapis 1: nomor yang diblokir pengguna langsung HIGH', () async {
    final (pipeline, store, _, ai) = await _build();
    await store.block('+6281298765432');

    final r = await pipeline.scan(_msg('halo'));

    expect(r.riskLevel, RiskLevel.high);
    expect(r.decidedByLayer, 1);
    expect(r.threatType, ThreatCodes.knownScammer);
    expect(r.showsOverlay, isTrue);
    expect(ai.calls, 0);
  });

  test(
    'Lapis 1: Bloom hit diterima saat luring (server tak terjangkau)',
    () async {
      final (pipeline, store, _, _) = await _build(
        directory: _FakeDirectory(unavailable: true),
      );
      await store.replaceCommunityList(['+6281298765432']);

      final r = await pipeline.scan(_msg('halo'));

      expect(r.riskLevel, RiskLevel.high);
      expect(r.decidedByLayer, 1);
    },
  );

  test(
    'Bloom hit tapi server tidak menemukan nomor = false positive, lanjut',
    () async {
      final (pipeline, store, _, _) = await _build(directory: _FakeDirectory());
      await store.replaceCommunityList(['+6281298765432']);

      final r = await pipeline.scan(_msg('Bro jadi makan bareng?'));

      expect(r.riskLevel, RiskLevel.low);
      expect(r.decidedByLayer, 3);
    },
  );

  test('Lapis 2: nomor dilaporkan komunitas >= ambang -> HIGH', () async {
    final (pipeline, _, _, ai) = await _build(
      directory: _FakeDirectory(
        entries: {
          '+6281298765432': const SpamEntry(
            key: '+6281298765432',
            reportCount: 5,
            riskLevel: RiskLevel.high,
            aiSummary: 'Penipuan paket palsu.',
          ),
        },
      ),
    );

    final r = await pipeline.scan(_msg('halo'));

    expect(r.riskLevel, RiskLevel.high);
    expect(r.decidedByLayer, 2);
    expect(r.aiSummary, 'Penipuan paket palsu.');
    expect(ai.calls, 0);
  });

  test('Lapis 3: .apk langsung HIGH tanpa memanggil AI', () async {
    final (pipeline, _, _, ai) = await _build();

    final r = await pipeline.scan(
      _msg(
        'UNDANGAN PERNIKAHAN digital.apk - Silahkan buka paket untuk melihat lokasi acara.',
      ),
    );

    expect(r.riskLevel, RiskLevel.high);
    expect(r.threatType, ThreatCodes.apkScam);
    expect(r.decidedByLayer, 3);
    expect(r.entities.fileExtension, '.apk');
    expect(ai.calls, 0);
  });

  test('Pesan wajar LOW tanpa memanggil AI (hemat token)', () async {
    final (pipeline, _, _, ai) = await _build();

    final r = await pipeline.scan(
      _msg('Bro jadi gak ntar malem makan bareng?'),
    );

    expect(r.riskLevel, RiskLevel.low);
    expect(r.actionRequired, ScanActions.none);
    expect(ai.calls, 0);
  });

  test('Lapis 4: kasus abu-abu diserahkan ke AI dan teks disanitasi', () async {
    final (pipeline, _, _, ai) = await _build(
      analyzer: _FakeAnalyzer(
        const CognitiveVerdict(
          riskLevel: RiskLevel.high,
          threatCode: ThreatCodes.financialPhishing,
          confidence: 0.91,
          summary: 'Janji untung berlipat setelah transfer.',
        ),
      ),
    );

    final r = await pipeline.scan(
      _msg('Selamat anda menang undian, transfer ke 081298765432 segera'),
    );

    expect(ai.calls, 1);
    expect(ai.lastText, isNot(contains('081298765432')));
    expect(r.riskLevel, RiskLevel.high);
    expect(r.decidedByLayer, 4);
    expect(r.aiSummary, 'Janji untung berlipat setelah transfer.');
  });

  test('AI mengatakan LOW tapi sinyal aturan kuat -> minimal MEDIUM', () async {
    final (pipeline, _, _, _) = await _build(
      analyzer: _FakeAnalyzer(
        const CognitiveVerdict(
          riskLevel: RiskLevel.low,
          threatCode: ThreatCodes.none,
          confidence: 0.6,
          summary: 'Tampak biasa.',
        ),
      ),
    );

    final r = await pipeline.scan(
      _msg('Selamat anda menang undian! tf 500rb ke rek BCA 1234567890 segera'),
    );

    expect(r.riskLevel, isNot(RiskLevel.low));
  });

  test(
    'AI tidak tersedia: keputusan memakai skor aturan saja (tidak error)',
    () async {
      final (pipeline, _, _, ai) = await _build(analyzer: _FakeAnalyzer(null));

      final r = await pipeline.scan(
        _msg(
          'Selamat anda menang undian! tf 500rb ke rek BCA 1234567890 segera',
        ),
      );

      expect(ai.calls, 1);
      expect(r.decidedByLayer, 3);
      expect(r.riskLevel, isNot(RiskLevel.low));
    },
  );

  test('Isi pesan tidak muncul pada hasil yang disimpan', () async {
    final (pipeline, _, _, _) = await _build();
    final r = await pipeline.scan(_msg('rahasia pribadi digital.apk'));

    expect(r.toStoredJson().toString(), isNot(contains('rahasia pribadi')));
  });

  group('GeminiAnalyzer.parseVerdict', () {
    test('mem-parse JSON, termasuk yang dibungkus code fence', () {
      final v = GeminiAnalyzer.parseVerdict('''```json
{"risk_level":"HIGH","threat_type":"APK_SCAM","confidence_score":0.93,"ai_summary":"Modus paket palsu."}
```''');
      expect(v, isNotNull);
      expect(v!.riskLevel, RiskLevel.high);
      expect(v.threatCode, 'APK_SCAM');
      expect(v.confidence, 0.93);
    });

    test('JSON rusak/kosong -> null', () {
      expect(GeminiAnalyzer.parseVerdict('bukan json'), isNull);
      expect(GeminiAnalyzer.parseVerdict(null), isNull);
      expect(GeminiAnalyzer.parseVerdict('[1,2]'), isNull);
    });
  });
}
