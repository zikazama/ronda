import 'package:latlong2/latlong.dart';
import 'package:ronda/core/geo/geo_index.dart';

/// Grid persegi sederhana sebagai pengganti H3 (native FFI) di tes.
class FakeGeoIndex implements GeoIndex {
  static const _step = 0.01;

  @override
  final int resolution = 8;

  @override
  String cellOf(LatLng p) =>
      '${(p.latitude / _step).floor()}_${(p.longitude / _step).floor()}';

  @override
  LatLng centerOf(String cell) {
    final (r, c) = _parse(cell);
    return LatLng((r + 0.5) * _step, (c + 0.5) * _step);
  }

  @override
  List<LatLng> boundaryOf(String cell) {
    final (r, c) = _parse(cell);
    return [
      LatLng(r * _step, c * _step),
      LatLng((r + 1) * _step, c * _step),
      LatLng((r + 1) * _step, (c + 1) * _step),
      LatLng(r * _step, (c + 1) * _step),
    ];
  }

  @override
  List<String> disk(String cell, int rings) {
    final (r, c) = _parse(cell);
    return [
      for (var dr = -rings; dr <= rings; dr++)
        for (var dc = -rings; dc <= rings; dc++) '${r + dr}_${c + dc}',
    ];
  }

  (int, int) _parse(String cell) {
    final parts = cell.split('_');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}
