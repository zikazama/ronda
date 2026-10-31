import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/detection/detection_service.dart';
import '../../../core/platform/native_bridge.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../scan/domain/scan_result.dart';

class _Preset {
  const _Preset(this.title, this.package, this.sender, this.body);
  final String title;
  final String package;
  final String sender;
  final String body;
}

const _presets = [
  _Preset(
    'Undangan pernikahan (APK)',
    'com.whatsapp',
    '+6281298765432',
    'UNDANGAN PERNIKAHAN digital.apk - Silahkan buka paket untuk melihat lokasi acara.',
  ),
  _Preset(
    'Surat tilang ETLE',
    'com.google.android.apps.messaging',
    '+6281234567890',
    'PENTING! Surat Tilang Elektronik ETLE No.882. Unduh file APK lampiran utk cek foto bukti.',
  ),
  _Preset(
    'Transfer & hadiah (slang)',
    'org.telegram.messenger',
    '+6285512340099',
    'Selamat anda menang undian! tf 500rb dulu ke rek BCA 1234567890 a/n Budi buat admin, segera ya gaskeun',
  ),
  _Preset(
    'Pesan biasa (aman)',
    'jp.naver.line.android',
    'Rina Kantor',
    'Bro jadi gak ntar malem makan bareng? Gw tf besok ya patungan kemarin',
  ),
];

/// Lembar uji: menjalankan pipeline deteksi yang sama dengan notifikasi asli,
/// untuk demo dan pengujian tanpa menunggu pesan penipuan sungguhan.
Future<void> showSimulateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => const _SimulateSheet(),
  );
}

class _SimulateSheet extends ConsumerStatefulWidget {
  const _SimulateSheet();

  @override
  ConsumerState<_SimulateSheet> createState() => _SimulateSheetState();
}

class _SimulateSheetState extends ConsumerState<_SimulateSheet> {
  String? _busy;

  Future<void> _run(_Preset p) async {
    setState(() => _busy = p.title);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final nav = Navigator.of(context);

    final result = await ref
        .read(detectionServiceProvider)
        .process(
          IncomingNotification(
            packageName: p.package,
            sender: p.sender,
            body: p.body,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
          simulated: true,
        );

    if (!mounted) return;
    nav.pop();
    if (result == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pemindaian gagal. Coba lagi.')),
      );
      return;
    }
    final saved = result.riskLevel != RiskLevel.low;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${result.riskLevel.label} • lapis ${result.decidedByLayer} • ${result.latencyMs} ms',
        ),
        action: saved
            ? SnackBarAction(
                label: 'Lihat',
                onPressed: () =>
                    router.push('${AppRoutes.analysis}/${result.scanId}'),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Simulasi pesan masuk', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Menjalankan pipeline deteksi yang sama seperti notifikasi asli.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final p in _presets)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: _busy == null,
                  title: Text(p.title, style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    p.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: _busy == p.title
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primary,
                        ),
                  onTap: () => _run(p),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
