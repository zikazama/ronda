import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/presentation/scan_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Deteksi')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: history.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => ScanTile(
          scan: history[i],
          onTap: () =>
              context.push('${AppRoutes.analysis}/${history[i].scanId}'),
        ),
      ),
    );
  }
}
