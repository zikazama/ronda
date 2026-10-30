import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/geo_index.dart';
import '../data/mock_heatmap_data.dart';
import '../domain/threat_zone.dart';

/// Seluruh zona ancaman (belum difilter).
final threatZonesProvider = Provider<List<ThreatZone>>(
  (ref) => MockHeatmapData.zones(ref.watch(geoIndexProvider)),
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

/// Zona setelah filter diterapkan.
final visibleZonesProvider = Provider<List<ThreatZone>>((ref) {
  final filter = ref.watch(threatFilterProvider);
  final zones = ref.watch(threatZonesProvider);
  if (filter == null) return zones;
  return zones.where((z) => z.kind == filter).toList(growable: false);
});

/// Sel H3 yang sedang dipilih pengguna.
class SelectedCellNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? cell) => state = cell;
}

final selectedCellProvider = NotifierProvider<SelectedCellNotifier, String?>(
  SelectedCellNotifier.new,
);
