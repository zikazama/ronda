import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/scan_result.dart';
import '../domain/threat_labels.dart';

/// Baris ringkas hasil pemindaian untuk daftar aktivitas / riwayat.
/// Judul = jenis ancaman (apa), baris kedua = pengirim (dari siapa).
class ScanTile extends StatelessWidget {
  const ScanTile({super.key, required this.scan, this.onTap});

  final ScanResult scan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final risk = scan.riskLevel;
    return Semantics(
      button: onTap != null,
      label:
          '${risk.label}. ${scan.threatTitle}. ${scan.platform.label}, '
          '${scan.sender}. ${timeAgo(scan.scannedAt)}.',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: risk.softColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(risk.icon, color: risk.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scan.threatTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo(scan.scannedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${scan.platform.label} dari ${scan.sender}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scan.aiSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
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
