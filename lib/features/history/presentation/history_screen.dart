import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/scan_result.dart';
import '../../scan/presentation/scan_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: history.isEmpty
          ? const _EmptyHistory()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                for (final group in _groupByDay(history)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      group.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final scan in group.items) ...[
                    ScanTile(
                      scan: scan,
                      onTap: () =>
                          context.push('${AppRoutes.analysis}/${scan.scanId}'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
    );
  }
}

class _DayGroup {
  _DayGroup(this.label);
  final String label;
  final List<ScanResult> items = [];
}

List<_DayGroup> _groupByDay(List<ScanResult> items, {DateTime? now}) {
  final today = _day(now ?? DateTime.now());
  final groups = <String, _DayGroup>{};
  for (final s in items) {
    final days = today.difference(_day(s.scannedAt)).inDays;
    final label = switch (days) {
      <= 0 => 'Hari ini',
      1 => 'Kemarin',
      _ => 'Sebelumnya',
    };
    groups.putIfAbsent(label, () => _DayGroup(label)).items.add(s);
  }
  return groups.values.toList(growable: false);
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text('Belum ada riwayat', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Pesan yang dinilai waspada atau berbahaya akan tersimpan di '
              'sini, lengkap dengan alasan dan langkah yang disarankan.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
