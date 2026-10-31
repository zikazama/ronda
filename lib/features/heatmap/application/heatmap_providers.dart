import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/cloud_gateway.dart';
import '../../../core/geo/geo_index.dart';
import '../data/mock_heatmap_data.dart';
import '../domain/threat_zone.dart';

/// Zona ancaman + penanda apakah datanya hanya contoh (Firebase belum aktif).
class HeatmapData {
  const HeatmapData(this.zones, {this.isDemo = false});

  final List<ThreatZone> zones;
  final bool isDemo;

  static const empty = HeatmapData([]);
}

/// Agregat `threat_cells` dari Firestore secara real-time. Bila Firebase
/// tidak tersedia, jatuh ke data contoh yang ditandai `isDemo`.
final heatmapDataProvider = StreamProvider<HeatmapData>((ref) async* {
  final geo = ref.watch(geoIndexProvider);
  final cloud = await ref.watch(cloudGatewayProvider).services();

  if (cloud == null) {
    yield HeatmapData(MockHeatmapData.zones(geo), isDemo: true);
    return;
  }

  final query = cloud.firestore
      .collection('threat_cells')
      .orderBy('lastReportAt', descending: true)
      .limit(400);

  yield* query.snapshots().map((snap) {
    final zones = <ThreatZone>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final cell = data['cell'] as String?;
      if (cell == null) continue;
      try {
        zones.add(
          ThreatZone(
            cell: cell,
            boundary: geo.boundaryOf(cell),
            center: geo.centerOf(cell),
            reports: (data['reports'] as num?)?.toInt() ?? 0,
            kind: ThreatKind.fromCode(data['kind'] as String? ?? ''),
            lastReportAt:
                (data['lastReportAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          ),
        );
      } on Object catch (e) {
        debugPrint('Sel H3 tidak valid dilewati ($cell): $e');
      }
    }
    return HeatmapData(zones);
  });
});

final isDemoDataProvider = Provider<bool>(
  (ref) => ref.watch(heatmapDataProvider).value?.isDemo ?? false,
);

/// Seluruh zona (belum difilter). Kosong selama data belum dimuat.
final threatZonesProvider = Provider<List<ThreatZone>>(
  (ref) => ref.watch(heatmapDataProvider).value?.zones ?? const [],
);

/// Filter jenis ancaman; `null` = semua.
class ThreatFilterNotifier extends Notifier<ThreatKind?> {
  @override
  ThreatKind? build() => null;

  void select(ThreatKind? kind) => state = kind;
}

final threatFilterProvider =
    NotifierProvider<ThreatFilterNotifier, ThreatKind?>(
      ThreatFilterNotifier.new,
    );

/// Zona setelah filter. Tanpa filter, dokumen per (sel, jenis) digabung per
/// sel: jumlah laporan dijumlahkan dan jenis dominan yang ditampilkan.
final visibleZonesProvider = Provider<List<ThreatZone>>((ref) {
  final filter = ref.watch(threatFilterProvider);
  final zones = ref.watch(threatZonesProvider);
  if (filter != null) {
    return zones.where((z) => z.kind == filter).toList(growable: false);
  }
  return mergeByCell(zones);
});

@visibleForTesting
List<ThreatZone> mergeByCell(List<ThreatZone> zones) {
  final byCell = <String, List<ThreatZone>>{};
  for (final z in zones) {
    byCell.putIfAbsent(z.cell, () => []).add(z);
  }
  return byCell.values
      .map((group) {
        if (group.length == 1) return group.first;
        final dominant = group.reduce((a, b) => a.reports >= b.reports ? a : b);
        return ThreatZone(
          cell: dominant.cell,
          boundary: dominant.boundary,
          center: dominant.center,
          reports: group.fold<int>(0, (s, z) => s + z.reports),
          kind: dominant.kind,
          lastReportAt: group
              .map((z) => z.lastReportAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        );
      })
      .toList(growable: false);
}

/// Sel H3 yang sedang dipilih pengguna.
class SelectedCellNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? cell) => state = cell;
}

final selectedCellProvider = NotifierProvider<SelectedCellNotifier, String?>(
  SelectedCellNotifier.new,
);
