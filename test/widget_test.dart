import 'package:flutter/widgets.dart' show Scrollable, Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:ronda/core/cloud/cloud_gateway.dart';

import 'package:ronda/app.dart';
import 'package:ronda/core/geo/geo_index.dart';
import 'package:ronda/core/router/app_router.dart';
import 'package:ronda/core/storage/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_geo_index.dart';

void main() {
  // appRouter adalah singleton; pastikan tiap tes mulai dari Beranda.
  setUp(() => appRouter.go(AppRoutes.home));

  testWidgets('beranda menampilkan keadaan kosong, lalu navigasi ke peta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          cloudGatewayProvider.overrideWithValue(
            CloudGateway(options: _noCloud),
          ),
          geoIndexProvider.overrideWithValue(FakeGeoIndex()),
        ],
        child: const RondaApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('RONDA SIBER'), findsOneWidget);
    expect(find.text('Aktivitas Terkini'), findsOneWidget);
    expect(find.text('Belum ada ancaman terdeteksi'), findsOneWidget);
    expect(find.text('Pesan dipindai'), findsOneWidget);

    await tester.tap(find.text('Peta'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Peta Sebaran'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('APK Palsu'), findsOneWidget);
    // Firebase belum dikonfigurasi di tes -> data contoh ditandai jelas.
    expect(find.textContaining('Data contoh'), findsOneWidget);
  });

  testWidgets('simulasi pesan APK menghasilkan riwayat berisiko', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          cloudGatewayProvider.overrideWithValue(
            CloudGateway(options: _noCloud),
          ),
          geoIndexProvider.overrideWithValue(FakeGeoIndex()),
        ],
        child: const RondaApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.text('Uji dengan pesan simulasi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Uji dengan pesan simulasi'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Undangan pernikahan (APK)'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Belum ada ancaman terdeteksi'), findsNothing);
    expect(find.textContaining('+6281298765432'), findsWidgets);
  });
}

/// Tanpa Firebase: menguji jalur luring/lokal.
const _noCloud = FirebaseOptions(
  apiKey: 'REPLACE_ME',
  appId: 'REPLACE_ME',
  messagingSenderId: 'REPLACE_ME',
  projectId: 'REPLACE_ME',
);
