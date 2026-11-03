import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_gateway.dart';
import '../../../core/detection/threat_list_store.dart';
import '../../../core/platform/protection_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../protection/permission_steps.dart';
import '../application/reputation.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(protectionStatusProvider).value;
    final rep = ref.watch(reputationProvider);
    final cloudConfigured = ref.watch(cloudGatewayProvider).isConfigured;
    final store = ref.watch(threatListStoreProvider);
    final steps = permissionSteps(status);

    final next = rep.next;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          // Pahlawan Siber
          Semantics(
            container: true,
            label:
                'Level ${rep.levelIndex + 1}, ${rep.level.name}. '
                '${rep.points} poin, ${rep.reports} laporan terkirim.',
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.night,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.nightRaised,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          color: AppColors.warningOnNight,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rep.level.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Level ${rep.levelIndex + 1} Pahlawan Siber',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
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
                      backgroundColor: AppColors.nightRaised,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.warningOnNight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    next == null
                        ? '${rep.points} poin • level tertinggi'
                        : '${rep.points} dari ${next.minPoints} poin menuju ${next.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  Text(
                    '${rep.reports} laporan terkirim',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text('Izin perlindungan', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) const Divider(),
                  _PermissionTile(
                    step: steps[i],
                    onTap: () => steps[i].request(context, ref),
                  ),
                ],
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
          const SizedBox(height: 28),

          Text('Sistem', style: theme.textTheme.titleLarge),
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
          const SizedBox(height: 28),

          Text('Privasi', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RONDA dirancang dengan prinsip Privacy by Design sesuai UU PDP. '
                  'Pesan dari kontak tersimpan diabaikan, isi pesan tidak pernah '
                  'disimpan, dan teks yang dianalisis AI disamarkan dari nomor '
                  'serta data pribadi.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Kebijakan privasi lengkap:',
                  style: theme.textTheme.bodySmall,
                ),
                SelectableText(
                  'https://ronda-kch-2026.web.app/privacy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.step, required this.onTap});

  final PermissionStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final granted = step.granted;
    return Semantics(
      button: true,
      label:
          '${step.title}. ${granted ? 'Sudah aktif' : 'Belum aktif'}. '
          '${step.subtitle}',
      excludeSemantics: true,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minVerticalPadding: 8,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: granted ? AppColors.safeSoft : AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.icon,
            color: granted ? AppColors.safe : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          step.title,
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 14.5),
        ),
        subtitle: Text(step.subtitle, style: theme.textTheme.bodySmall),
        trailing: granted
            ? const Icon(Icons.check_circle_rounded, color: AppColors.safe)
            : Text(
                'Aktifkan',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
