import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../core/platform/native_bridge.dart';
import '../../core/platform/protection_status.dart';

/// Satu izin yang membuat RONDA bisa berjaga, beserta cara memintanya.
/// Dipakai di Beranda (panduan awal) dan Profil (daftar izin).
class PermissionStep {
  const PermissionStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.required,
    required this.request,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;

  /// `true` bila proteksi tidak berjalan tanpa izin ini.
  final bool required;

  /// Menampilkan penjelasan lalu membuka pengaturan sistem yang sesuai.
  final Future<void> Function(BuildContext context, WidgetRef ref) request;
}

/// Urutan di sini adalah urutan langkah yang disarankan.
List<PermissionStep> permissionSteps(ProtectionStatus? s) {
  final bridge = NativeBridge.instance;
  return [
    PermissionStep(
      id: 'notification',
      icon: Icons.notifications_active_outlined,
      title: 'Akses notifikasi',
      subtitle: 'Membaca notifikasi SMS dan aplikasi pesan',
      granted: s?.notificationAccess ?? false,
      required: true,
      request: (context, ref) async {
        final ok = await showDisclosure(
          context,
          title: 'Izinkan RONDA membaca notifikasi?',
          body:
              'RONDA membaca teks notifikasi SMS, WhatsApp, Telegram, dan '
              'aplikasi pesan lain hanya untuk mengenali penipuan, phishing, '
              'dan file APK berbahaya.\n\n'
              '• Isi pesan tidak disimpan dan tidak dijual.\n'
              '• Teks yang dianalisis AI disamarkan dari nomor, email, dan '
              'angka panjang.\n'
              '• Pesan dari kontak tersimpan dilewati.\n\n'
              'Di layar berikutnya, aktifkan RONDA pada daftar Akses '
              'Notifikasi.\n\n'
              'Jika opsinya abu-abu (aplikasi dipasang manual, Android 13+): '
              'buka Info Aplikasi RONDA, ketuk menu ⋮, pilih "Izinkan '
              'setelan terbatas", lalu ulangi.',
          confirmLabel: 'Lanjut',
          extraLabel: 'Buka Info Aplikasi',
          onExtra: openAppSettings,
        );
        if (ok) await bridge.openNotificationAccessSettings();
      },
    ),
    PermissionStep(
      id: 'overlay',
      icon: Icons.layers_outlined,
      title: 'Tampil di atas aplikasi lain',
      subtitle: 'Peringatan layar penuh saat ada ancaman',
      granted: s?.overlay ?? false,
      required: true,
      request: (context, ref) => bridge.openOverlaySettings(),
    ),
    PermissionStep(
      id: 'battery',
      icon: Icons.battery_charging_full_rounded,
      title: 'Tanpa batasan baterai',
      subtitle: 'Agar proteksi tidak dimatikan sistem saat aplikasi ditutup',
      granted: s?.battery ?? false,
      required: false,
      request: (context, ref) => bridge.openBatterySettings(),
    ),
    PermissionStep(
      id: 'contacts',
      icon: Icons.contacts_outlined,
      title: 'Kontak (opsional)',
      subtitle: 'Pesan dari kontak tersimpan dilewati, tidak dianalisis',
      granted: s?.contacts ?? false,
      required: false,
      request: (context, ref) async {
        final ok = await showDisclosure(
          context,
          title: 'Izinkan akses kontak?',
          body:
              'RONDA memeriksa apakah pengirim pesan ada di kontak Anda. Jika '
              'ya, pesan itu dilewati dan tidak dianalisis.\n\n'
              '• Daftar kontak tidak dikirim ke server dan tidak disimpan.\n'
              '• Pemeriksaan dilakukan di perangkat Anda.\n'
              '• Izin ini opsional; tanpanya semua pengirim dianalisis.',
          confirmLabel: 'Izinkan',
        );
        if (!ok) return;
        await bridge.requestContacts();
        await ref.read(protectionStatusProvider.notifier).refresh();
      },
    ),
  ];
}

/// Penjelasan yang tampil SEBELUM pengguna dibawa ke izin sensitif
/// (syarat "prominent disclosure" Google Play). `true` bila pengguna lanjut.
Future<bool> showDisclosure(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String? extraLabel,
  Future<void> Function()? onExtra,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(body)),
      actions: [
        if (extraLabel != null && onExtra != null)
          TextButton(onPressed: onExtra, child: Text(extraLabel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
