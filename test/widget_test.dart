import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronda/app.dart';
import 'package:ronda/core/geo/geo_index.dart';

import 'fakes/fake_geo_index.dart';

void main() {
  testWidgets('menampilkan beranda RONDA dan navigasi bawah', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [geoIndexProvider.overrideWithValue(FakeGeoIndex())],
        child: const RondaApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('RONDA SIBER'), findsOneWidget);
    expect(find.text('SISTEM AKTIF & AMAN'), findsOneWidget);
    expect(find.text('Aktivitas Terkini'), findsOneWidget);

    await tester.tap(find.text('Peta'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Peta Sebaran'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('APK Palsu'), findsOneWidget);
    expect(find.textContaining('Laporan'), findsOneWidget);
  });
}
