import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/protection_status.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../protection/permission_steps.dart';
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
    final top = MediaQuery.paddingOf(context).top;

    final steps = permissionSteps(
      status,
    ).where((s) => s.id != 'contacts').toList();
    final showSetup =
        status != null && status.supported && steps.any((s) => !s.granted);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Panel malam di atas: ikon status bar harus terang.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Hero(
                    status: status,
                    steps: steps,
                    scanned: scanned,
                    threats: threats,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  sliver: SliverList.list(
                    children: [
                      if (showSetup) ...[
                        _SetupCard(
                          steps: steps,
                          protectionActive: status.isActive,
                        ),
                        const SizedBox(height: 28),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Aktivitas terkini',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          if (history.isNotEmpty)
                            TextButton(
                              onPressed: () => context.go(AppRoutes.history),
                              child: const Text('Lihat semua'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (history.isEmpty)
                        const _EmptyActivity()
                      else
                        for (final scan in history.take(3)) ...[
                          ScanTile(
                            scan: scan,
                            onTap: () => context.push(
                              '${AppRoutes.analysis}/${scan.scanId}',
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => showSimulateSheet(context),
                          icon: const Icon(Icons.science_outlined, size: 20),
                          label: const Text('Coba dengan pesan simulasi'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pesan dari kontak tersimpan tidak dianalisis. '
                              'Isi pesan tidak disimpan dan tidak dikirim ke server.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Menjaga ikon status bar tetap terbaca saat konten digulir.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: top,
              child: const ColoredBox(color: AppColors.night),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Mode { checking, demo, inactive, active }

class _Hero extends ConsumerWidget {
  const _Hero({
    required this.status,
    required this.steps,
    required this.scanned,
    required this.threats,
  });

  final ProtectionStatus? status;
  final List<PermissionStep> steps;
  final int scanned;
  final int threats;

  _Mode get _mode {
    final s = status;
    if (s == null) return _Mode.checking;
    if (!s.supported) return _Mode.demo;
    return s.isActive ? _Mode.active : _Mode.inactive;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final mode = _mode;

    final missing = steps.where((s) => s.required && !s.granted).toList();

    final (headline, detail, radarColor) = switch (mode) {
      _Mode.checking => (
        'Memeriksa…',
        'Sebentar, RONDA sedang memeriksa izin.',
        AppColors.textMuted,
      ),
      _Mode.demo => (
        'Mode demo.',
        'Pemantauan notifikasi hanya berjalan di Android. Di sini Anda bisa '
            'mencoba lewat pesan simulasi.',
        AppColors.warningOnNight,
      ),
      _Mode.inactive => (
        'Ronda belum berjaga.',
        'Aktifkan ${missing.length} izin lagi agar pesan penipuan bisa dikenali.',
        AppColors.dangerOnNight,
      ),
      _Mode.active => (
        'Ronda sedang berjaga.',
        'Memantau SMS, WhatsApp, dan aplikasi pesan lainnya.',
        AppColors.safeOnNight,
      ),
    };

    // Teks tidak boleh menabrak radar yang terpotong di tepi kanan.
    final textWidth = (width - 40) * 0.66;

    return Semantics(
      container: true,
      label: '$headline $detail $scanned pesan dipindai, $threats ancaman dicegah.',
      child: Container(
        width: double.infinity,
        color: AppColors.night,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -118,
              top: top + 36,
              child: RadarView(
                size: 270,
                color: radarColor,
                active: mode == _Mode.active,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.radar_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ronda',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: textWidth),
                    child: Text(headline, style: theme.textTheme.displaySmall),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: textWidth),
                    child: Text(
                      detail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                  if (mode == _Mode.inactive && missing.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.night,
                      ),
                      onPressed: () => missing.first.request(context, ref),
                      child: const Text('Aktifkan sekarang'),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Divider(color: Colors.white.withValues(alpha: 0.14)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Stat(value: scanned, label: 'pesan dipindai'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Stat(value: threats, label: 'ancaman dicegah'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// Panduan awal. Langkahnya berurutan, jadi diberi nomor.
class _SetupCard extends ConsumerWidget {
  const _SetupCard({required this.steps, required this.protectionActive});

  final List<PermissionStep> steps;
  final bool protectionActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final done = steps.where((s) => s.granted).length;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            protectionActive
                ? 'Satu langkah lagi agar tidak mati sendiri'
                : 'Selesaikan pengaturan',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            '$done dari ${steps.length} selesai',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              number: i + 1,
              step: steps[i],
              onTap: () => steps[i].request(context, ref),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.step,
    required this.onTap,
  });

  final int number;
  final PermissionStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = step.granted;
    return Semantics(
      button: !done,
      label:
          'Langkah $number, ${step.title}, ${done ? 'sudah aktif' : 'belum aktif'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: done ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.safe : Colors.transparent,
                    border: done
                        ? null
                        : Border.all(color: AppColors.textMuted, width: 1.5),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        )
                      : Text(
                          '$number',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14.5,
                          color: done
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (!done)
                        Text(step.subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (!done)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 28,
            color: AppColors.safe,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Belum ada ancaman', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Pesan berbahaya yang terdeteksi akan muncul di sini.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
