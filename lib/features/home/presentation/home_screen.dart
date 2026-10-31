import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/protection_status.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/presentation/scan_tile.dart';
import 'radar_view.dart';
import 'simulate_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(scanHistoryProvider);
    final threats = ref.watch(threatCountProvider);
    final scanned = ref.watch(scannedCountProvider);
    final status = ref.watch(protectionStatusProvider).value;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(threats: threats, scanned: scanned, status: status),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.list(
              children: [
                SectionTitle(
                  'Aktivitas Terkini',
                  trailing: history.isEmpty
                      ? null
                      : TextButton(
                          onPressed: () => context.go(AppRoutes.history),
                          child: const Text('Lihat semua'),
                        ),
                ),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const _EmptyActivity()
                else
                  for (final scan in history.take(3)) ...[
                    ScanTile(
                      scan: scan,
                      onTap: () =>
                          context.push('${AppRoutes.analysis}/${scan.scanId}'),
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () => showSimulateSheet(context),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Uji dengan pesan simulasi'),
                ),
                const SizedBox(height: 14),
                AppCard(
                  color: AppColors.primarySoft,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pesan dari kontak tersimpan tidak pernah dianalisis atau dikirim ke server. Isi pesan tidak disimpan.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
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

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.shield_moon_outlined,
            size: 36,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada ancaman terdeteksi',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Peringatan akan muncul di sini saat ada pesan berbahaya.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.threats,
    required this.scanned,
    required this.status,
  });

  final int threats;
  final int scanned;
  final ProtectionStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;

    final (label, color, soft, action) = _statusStyle(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'RONDA SIBER',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                RadarView(size: 190, color: color),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: color),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.profile),
                    child: Text(action),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Stat(value: '$scanned', label: 'Pesan dipindai'),
                    const SizedBox(width: 12),
                    _Stat(value: '$threats', label: 'Ancaman dicegah'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// (label, warna, warna lembut, teks tombol aksi)
  (String, Color, Color, String?) _statusStyle(ProtectionStatus? s) {
    if (s == null) {
      return ('MEMERIKSA…', AppColors.textMuted, AppColors.background, null);
    }
    if (!s.supported) {
      return (
        'MODE DEMO • PROTEKSI HANYA DI ANDROID',
        AppColors.warning,
        AppColors.warningSoft,
        null,
      );
    }
    if (!s.isActive) {
      return (
        'PROTEKSI BELUM AKTIF',
        AppColors.danger,
        AppColors.dangerSoft,
        'Aktifkan izin',
      );
    }
    return ('SISTEM AKTIF & AMAN', AppColors.safe, AppColors.safeSoft, null);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
