import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_scan_data.dart';
import '../domain/scan_result.dart';

/// Riwayat pemindaian terbaru. Saat ini memakai data contoh.
final scanHistoryProvider = Provider<List<ScanResult>>(
  (ref) => MockScanData.recent(),
);

/// Jumlah ancaman (risiko MEDIUM/HIGH) pada riwayat.
final threatCountProvider = Provider<int>(
  (ref) => ref
      .watch(scanHistoryProvider)
      .where((e) => e.riskLevel != RiskLevel.low)
      .length,
);
