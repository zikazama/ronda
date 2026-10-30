import 'package:latlong2/latlong.dart';

import '../../../core/geo/geo_index.dart';
import '../domain/threat_zone.dart';

/// Data contoh sebaran ancaman di Jakarta. Ganti dengan data agregat dari
/// backend (tabel laporan yang dikelompokkan per `h3_location`).
abstract final class MockHeatmapData {
  static const center = LatLng(-6.2088, 106.8456);

  static const _seeds = [
    (LatLng(-6.1860, 106.8110), 18, ThreatKind.apkScam), // Tanah Abang
    (LatLng(-6.1754, 106.8272), 14, ThreatKind.financialPhishing), // Monas
    (LatLng(-6.2297, 106.8300), 16, ThreatKind.impersonation), // Kuningan
    (LatLng(-6.1352, 106.8133), 11, ThreatKind.apkScam), // Kota Tua
    (LatLng(-6.2441, 106.7993), 9, ThreatKind.financialPhishing), // Blok M
    (LatLng(-6.2420, 106.8680), 12, ThreatKind.apkScam), // Cawang
  ];

  static List<ThreatZone> zones(GeoIndex geo, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final byCell = <String, ThreatZone>{};

    for (final (point, peak, kind) in _seeds) {
      final origin = geo.cellOf(point);
      final rings = geo.disk(origin, 1);
      for (var i = 0; i < rings.length; i++) {
        final cell = rings[i];
        final isOrigin = cell == origin;
        // Sel tepi lebih rendah; variasi deterministik agar tampilan stabil.
        final reports = isOrigin
            ? peak
            : (peak * (0.25 + 0.1 * (i % 4))).round().clamp(1, peak);
        final existing = byCell[cell];
        if (existing != null && existing.reports >= reports) continue;
        byCell[cell] = ThreatZone(
          cell: cell,
          boundary: geo.boundaryOf(cell),
          center: geo.centerOf(cell),
          reports: reports,
          kind: kind,
          lastReportAt: clock.subtract(Duration(minutes: 7 + i * 23)),
        );
      }
    }
    return byCell.values.toList(growable: false);
  }
}
