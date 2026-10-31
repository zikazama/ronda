import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'native_bridge.dart';

/// Status izin yang dibutuhkan agar proteksi berjalan.
class ProtectionStatus {
  const ProtectionStatus({
    required this.supported,
    required this.notificationAccess,
    required this.overlay,
    required this.contacts,
  });

  /// `false` di web/desktop: pemantauan notifikasi hanya ada di Android.
  final bool supported;
  final bool notificationAccess;
  final bool overlay;
  final bool contacts;

  /// Pemantauan + peringatan siap. Izin kontak opsional (tanpanya semua
  /// pengirim dianalisis, termasuk kontak tersimpan).
  bool get isActive => supported && notificationAccess && overlay;

  static const unsupported = ProtectionStatus(
    supported: false,
    notificationAccess: false,
    overlay: false,
    contacts: false,
  );
}

class ProtectionStatusNotifier extends AsyncNotifier<ProtectionStatus> {
  @override
  Future<ProtectionStatus> build() => _load();

  /// Dipanggil saat aplikasi kembali dari pengaturan sistem.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<ProtectionStatus> _load() async {
    final bridge = NativeBridge.instance;
    if (!bridge.isSupported) return ProtectionStatus.unsupported;
    final results = await Future.wait([
      bridge.isNotificationAccessGranted(),
      bridge.isOverlayGranted(),
      bridge.isContactsGranted(),
    ]);
    return ProtectionStatus(
      supported: true,
      notificationAccess: results[0],
      overlay: results[1],
      contacts: results[2],
    );
  }
}

final protectionStatusProvider =
    AsyncNotifierProvider<ProtectionStatusNotifier, ProtectionStatus>(
      ProtectionStatusNotifier.new,
    );
