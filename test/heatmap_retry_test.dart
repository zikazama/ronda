import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronda/core/cloud/cloud_gateway.dart';
import 'package:ronda/core/geo/geo_index.dart';
import 'package:ronda/features/heatmap/application/heatmap_providers.dart';

import 'fakes/fake_geo_index.dart';

const _anyOptions = FirebaseOptions(
  apiKey: 'REPLACE_ME',
  appId: 'REPLACE_ME',
  messagingSenderId: 'REPLACE_ME',
  projectId: 'REPLACE_ME',
);

/// Firebase terkonfigurasi tetapi sambungan gagal (mis. jaringan belum siap).
class _OfflineGateway extends CloudGateway {
  _OfflineGateway() : super(options: _anyOptions);

  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<CloudServices?> services() async {
    calls++;
    return null;
  }
}

void main() {
  testWidgets(
    'peta tidak menetap di data contoh: mencoba terhubung lagi secara berkala',
    (tester) async {
      final gateway = _OfflineGateway();
      final container = ProviderContainer(
        overrides: [
          cloudGatewayProvider.overrideWithValue(gateway),
          geoIndexProvider.overrideWithValue(FakeGeoIndex()),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(heatmapDataProvider, (_, _) {});
      await tester.pump(const Duration(milliseconds: 100));

      // Selama belum terhubung, tampil data contoh yang ditandai jelas.
      expect(container.read(heatmapDataProvider).value?.isDemo, isTrue);
      final firstCalls = gateway.calls;
      expect(firstCalls, 1);

      // Setelah jeda, mencoba lagi (sebelumnya hanya sekali seumur proses).
      await tester.pump(const Duration(seconds: 25));
      expect(gateway.calls, greaterThan(firstCalls));

      // Ditutup: pengulangan berhenti dan tidak ada timer yang tertinggal.
      sub.close();
      container.dispose();
      await tester.pump(const Duration(seconds: 25));
    },
  );
}
