import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Lokasi pengguna. Memakai akurasi rendah (coarse) sengaja: RONDA hanya
/// membutuhkan wilayah kasar (sel H3), bukan titik presisi.
class LocationService {
  const LocationService();

  /// Lokasi kasar HANYA bila izin sudah diberikan sebelumnya. Tidak memunculkan
  /// dialog izin, aman dipanggil dari jalur latar belakang. `null` bila tak ada.
  Future<LatLng?> currentIfPermitted() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final pos =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
      return LatLng(pos.latitude, pos.longitude);
    } on Object {
      return null;
    }
  }

  Future<LatLng> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Layanan lokasi nonaktif. Aktifkan GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('Izin lokasi ditolak.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Izin lokasi diblokir. Aktifkan lewat pengaturan aplikasi.',
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } on Exception {
      throw const LocationException('Gagal mendapatkan lokasi. Coba lagi.');
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);
