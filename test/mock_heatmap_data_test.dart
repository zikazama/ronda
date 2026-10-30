import 'package:flutter_test/flutter_test.dart';
import 'package:ronda/features/heatmap/data/mock_heatmap_data.dart';

import 'fakes/fake_geo_index.dart';

void main() {
  test('zona ancaman unik per sel dan intensitas terisi', () {
    final zones = MockHeatmapData.zones(FakeGeoIndex());

    expect(zones, isNotEmpty);
    expect(zones.map((z) => z.cell).toSet().length, zones.length);
    expect(zones.every((z) => z.reports > 0), isTrue);
    expect(zones.every((z) => z.boundary.length >= 4), isTrue);
  });
}
