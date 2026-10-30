import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/risk_badge.dart';
import '../../../core/widgets/section_title.dart';
import '../../scan/application/scan_providers.dart';
import '../../scan/domain/detection_layer.dart';
import '../../scan/domain/scan_result.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key, required this.scanId});

  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref
        .watch(scanHistoryProvider)
        .where((e) => e.scanId == scanId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: scan == null
          ? const Center(child: Text('Data pemindaian tidak ditemukan'))
          : _Content(scan: scan),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.scan});

  final ScanResult scan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final risk = scan.riskLevel;
    final entities = scan.entities;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              // Banner peringatan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: risk.softColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(risk.icon, color: risk.color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'PERINGATAN: ${scan.threatType.replaceAll('_', ' ')}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scan.aiSummary,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ringkasan
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(label: 'Platform', value: scan.platform.label),
                    const Divider(height: 24),
                    _InfoRow(label: 'Pengirim', value: scan.sender),
                    const Divider(height: 24),
                    _InfoRow(
                      label: 'Tingkat risiko',
                      valueWidget: RiskBadge(risk),
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      label: 'Keyakinan AI',
                      value: '${(scan.confidenceScore * 100).round()}%',
                    ),
                    if (entities.fileExtension != null) ...[
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'Ekstensi file',
                        value: entities.fileExtension!,
                      ),
                    ],
                    if (entities.bankAccount != null) ...[
                      const Divider(height: 24),
                      _InfoRow(label: 'Rekening', value: entities.bankAccount!),
                    ],
                    if (entities.suspiciousUrl != null) ...[
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'URL mencurigakan',
                        value: entities.suspiciousUrl!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Alur deteksi
              const SectionTitle('Alur Deteksi'),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    for (final layer in DetectionLayer.pipeline)
                      _LayerStep(
                        layer: layer,
                        isLast: layer == DetectionLayer.pipeline.last,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Aksi
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${scan.sender} diblokir')),
                      );
                    },
                    child: const Text('Blokir Nomor'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Abaikan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 16),
        Flexible(
          child:
              valueWidget ??
              Text(
                value ?? '-',
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

class _LayerStep extends StatelessWidget {
  const _LayerStep({required this.layer, required this.isLast});

  final DetectionLayer layer;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${layer.order}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.primarySoft),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          layer.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '< ${layer.targetMs} ms',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    layer.engine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(layer.description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
