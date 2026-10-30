import 'package:flutter/material.dart';

import '../../../core/platform/native_bridge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool _notificationAccess = false;
  bool _overlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Segarkan status izin saat pengguna kembali dari pengaturan sistem.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final bridge = NativeBridge.instance;
    final results = await Future.wait([
      bridge.isNotificationAccessGranted(),
      bridge.isOverlayGranted(),
    ]);
    if (!mounted) return;
    setState(() {
      _notificationAccess = results[0];
      _overlay = results[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bridge = NativeBridge.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          // Pahlawan Siber
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.military_tech_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pahlawan Siber',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Level 2 • Penjaga Lingkungan',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    value: 0.62,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '620 / 1000 poin reputasi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SectionTitle('Izin Perlindungan'),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _PermissionTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Akses Notifikasi',
                  subtitle: 'Membaca notifikasi SMS & aplikasi pesan',
                  granted: _notificationAccess,
                  onTap: bridge.openNotificationAccessSettings,
                ),
                const Divider(),
                _PermissionTile(
                  icon: Icons.layers_outlined,
                  title: 'Tampil di Atas Aplikasi Lain',
                  subtitle: 'Peringatan overlay saat ancaman terdeteksi',
                  granted: _overlay,
                  onTap: bridge.openOverlaySettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SectionTitle('Privasi'),
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              'RONDA dirancang dengan prinsip Privacy by Design sesuai UU PDP. '
              'Pesan dari kontak tersimpan diabaikan, dan pesan pribadi tidak '
              'pernah disimpan di server.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontSize: 14.5),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Icon(
        granted ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
        color: granted ? AppColors.safe : AppColors.textMuted,
      ),
    );
  }
}
