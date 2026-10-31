import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ronda/core/storage/prefs.dart';
import 'package:ronda/features/heatmap/application/heatmap_providers.dart';
import 'package:ronda/features/heatmap/domain/threat_zone.dart';
import 'package:ronda/features/profile/application/reputation.dart';
import 'package:ronda/features/scan/application/scan_providers.dart';
import 'package:ronda/features/scan/domain/scan_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

ScanResult _scan(String id) => ScanResult(
  scanId: id,
  platform: MessagePlatform.whatsapp,
  sender: '+6281298765432',
  riskLevel: RiskLevel.high,
  threatType: 'APK_SCAM',
  confidenceScore: 0.9,
  aiSummary: 'ringkasan',
  entities: const ExtractedEntities(fileExtension: '.apk'),
  actionRequired: 'SHOW_POPUP_ALERT_AND_SOUND',
  scannedAt: DateTime.now(),
  decidedByLayer: 3,
  latencyMs: 12,
);

ThreatZone _zone(String cell, int reports, ThreatKind kind, DateTime at) =>
    ThreatZone(
      cell: cell,
      boundary: const [LatLng(0, 0), LatLng(0, 1), LatLng(1, 1), LatLng(1, 0)],
      center: const LatLng(0.5, 0.5),
      reports: reports,
      kind: kind,
      lastReportAt: at,
    );

void main() {
  test('riwayat tersimpan dan dimuat ulang tanpa isi pesan', () async {
    final c = await _container();
    await c.read(scanHistoryProvider.notifier).add(_scan('sc_1'));
    await c.read(scanHistoryProvider.notifier).add(_scan('sc_2'));

    final prefs = c.read(sharedPreferencesProvider);
    final c2 = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c2.dispose);

    final restored = c2.read(scanHistoryProvider);
    expect(restored.map((e) => e.scanId), ['sc_2', 'sc_1']);
    expect(restored.first.entities.fileExtension, '.apk');
    expect(restored.first.decidedByLayer, 3);
  });

  test('riwayat dibatasi jumlahnya', () async {
    final c = await _container();
    final notifier = c.read(scanHistoryProvider.notifier);
    for (var i = 0; i < 120; i++) {
      await notifier.add(_scan('sc_$i'));
    }
    expect(c.read(scanHistoryProvider).length, 100);
    expect(c.read(scanHistoryProvider).first.scanId, 'sc_119');
  });

  test('reputasi naik level sesuai poin', () async {
    final c = await _container();
    expect(c.read(reputationProvider).level.name, 'Warga Waspada');

    for (var i = 0; i < 4; i++) {
      await c.read(reputationProvider.notifier).awardReport(25);
    }
    final rep = c.read(reputationProvider);
    expect(rep.points, 100);
    expect(rep.reports, 4);
    expect(rep.level.name, 'Penjaga Lingkungan');
    expect(rep.progress, 0);
  });

  test('mergeByCell menjumlahkan laporan & memilih jenis dominan', () {
    final t = DateTime(2026, 10, 30, 10);
    final merged = mergeByCell([
      _zone('a', 3, ThreatKind.apkScam, t),
      _zone(
        'a',
        7,
        ThreatKind.financialPhishing,
        t.add(const Duration(hours: 1)),
      ),
      _zone('b', 2, ThreatKind.impersonation, t),
    ]);

    expect(merged.length, 2);
    final a = merged.firstWhere((z) => z.cell == 'a');
    expect(a.reports, 10);
    expect(a.kind, ThreatKind.financialPhishing);
    expect(a.lastReportAt, t.add(const Duration(hours: 1)));
  });
}
