import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:h3_flutter/h3_flutter.dart' as h3;
import 'package:latlong2/latlong.dart';

/// Pengindeks geospasial heksagonal. Dipisah sebagai interface supaya mudah
/// diganti saat pengujian (H3 memakai native FFI).
abstract interface class GeoIndex {
  /// Resolusi H3 yang dipakai. 8 ≈ 0,7 km² per sel: cukup kasar untuk
  /// menganonimkan lokasi pengguna, cukup halus untuk memetakan wilayah.
  int get resolution;

  /// Kode sel H3 (hex string, mis. `88309a4a11fffff`) untuk sebuah titik.
  String cellOf(LatLng point);

  /// Titik tengah sel.
  LatLng centerOf(String cell);

  /// Poligon batas sel.
  List<LatLng> boundaryOf(String cell);

  /// Sel dalam radius [rings] dari [cell] (termasuk [cell]).
  List<String> disk(String cell, int rings);
}

class H3GeoIndex implements GeoIndex {
  H3GeoIndex(this._h3);

  final h3.H3 _h3;

  @override
  final int resolution = 8;

  @override
  String cellOf(LatLng point) => _h3
      .geoToCell(
        h3.GeoCoord(lat: point.latitude, lon: point.longitude),
        resolution,
      )
      .toRadixString(16);

  @override
  LatLng centerOf(String cell) {
    final c = _h3.cellToGeo(_parse(cell));
    return LatLng(c.lat, c.lon);
  }

  @override
  List<LatLng> boundaryOf(String cell) => _h3
      .cellToBoundary(_parse(cell))
      .map((c) => LatLng(c.lat, c.lon))
      .toList(growable: false);

  @override
  List<String> disk(String cell, int rings) => _h3
      .gridDisk(_parse(cell), rings)
      .map((e) => e.toRadixString(16))
      .toList(growable: false);

  BigInt _parse(String cell) => BigInt.parse(cell, radix: 16);
}

/// Dimuat lazy: native H3 baru dibuka saat pertama dipakai.
final geoIndexProvider = Provider<GeoIndex>(
  (ref) => H3GeoIndex(const h3.H3Factory().load()),
);
