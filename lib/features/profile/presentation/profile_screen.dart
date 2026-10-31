import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_gateway.dart';
import '../../../core/detection/threat_list_store.dart';
import '../../../core/platform/native_bridge.dart';
import '../../../core/platform/protection_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../application/reputation.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bridge = NativeBridge.instance;
    final status = ref.watch(protectionStatusProvider).value;
    final rep = ref.watch(reputationProvider);
    final cloudConfigured = ref.watch(cloudGatewayProvider).isConfigured;
    final store = ref.watch(threatListStoreProvider);

    final next = rep.next;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pahlawan Siber',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Level ${rep.levelIndex + 1} • ${rep.level.name}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: rep.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  next == null
                      ? '${rep.points} poin • level tertinggi'
                      : '${rep.points} / ${next.minPoints} poin menuju ${next.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rep.reports} laporan terkirim',
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
                  granted: status?.notificationAccess ?? false,
                  onTap: bridge.openNotificationAccessSettings,
                ),
                const Divider(),
                _PermissionTile(
                  icon: Icons.layers_outlined,
                  title: 'Tampil di Atas Aplikasi Lain',
                  subtitle: 'Peringatan overlay saat ancaman terdeteksi',
                  granted: status?.overlay ?? false,
                  onTap: bridge.openOverlaySettings,
                ),
                const Divider(),
                _PermissionTile(
                  icon: Icons.contacts_outlined,
                  title: 'Kontak (opsional)',
                  subtitle:
                      'Pesan dari kontak tersimpan dilewati, tidak dianalisis',
                  granted: status?.contacts ?? false,
                  onTap: () async {
                    await bridge.requestContacts();
                    ref.read(protectionStatusProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),
          if (status != null && !status.supported) ...[
            const SizedBox(height: 8),
            Text(
              'Pemantauan notifikasi hanya tersedia di Android.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),

          const SectionTitle('Sistem'),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: cloudConfigured
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  label: 'Basis data komunitas',
                  value: cloudConfigured ? 'Firebase aktif' : 'Mode lokal',
                  ok: cloudConfigured,
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.sync_rounded,
                  label: 'Daftar penipu luring',
                  value: store.lastSyncedAt == null
                      ? 'Belum disinkronkan'
                      : 'Disinkronkan',
                  ok: store.lastSyncedAt != null,
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.block_rounded,
                  label: 'Nomor diblokir',
                  value: '${store.blocklist.length}',
                  ok: true,
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
              'Pesan dari kontak tersimpan diabaikan, isi pesan tidak pernah '
              'disimpan, dan teks yang dianalisis AI disamarkan dari nomor '
              'serta data pribadi.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: ok ? AppColors.safe : AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
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
