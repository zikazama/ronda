import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/geo/geo_index.dart';
import '../../../core/geo/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_ago.dart';
import '../application/heatmap_providers.dart';
import '../data/mock_heatmap_data.dart';
import '../domain/threat_zone.dart';

const _defaultZoom = 11.8;

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  final _controller = MapController();
  LatLng? _me;
  bool _locating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    final zones = ref.read(visibleZonesProvider);
    final cell = ref.read(geoIndexProvider).cellOf(point);
    final hit = zones.any((z) => z.cell == cell);
    ref.read(selectedCellProvider.notifier).select(hit ? cell : null);
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final point = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      setState(() => _me = point);
      _controller.move(point, 14);

      // Jika berada di zona rawan, langsung tampilkan detailnya.
      final cell = ref.read(geoIndexProvider).cellOf(point);
      final inZone = ref.read(threatZonesProvider).any((z) => z.cell == cell);
      ref.read(selectedCellProvider.notifier).select(inZone ? cell : null);
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _resetView() {
    _controller.move(MockHeatmapData.center, _defaultZoom);
    ref.read(selectedCellProvider.notifier).select(null);
  }

  @override
  Widget build(BuildContext context) {
    final allZones = ref.watch(threatZonesProvider);
    final zones = ref.watch(visibleZonesProvider);
    final selected = ref.watch(selectedCellProvider);
    final maxReports = allZones.fold<int>(
      1,
      (m, z) => z.reports > m ? z.reports : m,
    );

    final selectedZone = zones.where((z) => z.cell == selected).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Peta Sebaran')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FlutterMap(
                      mapController: _controller,
                      options: MapOptions(
                        initialCenter: MockHeatmapData.center,
                        initialZoom: _defaultZoom,
                        minZoom: 5,
                        maxZoom: 18,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        onTap: (_, point) => _onMapTap(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: AppConstants.packageId,
                          maxNativeZoom: 19,
                        ),
                        PolygonLayer(
                          polygons: [
                            for (final z in zones)
                              _polygonFor(z, maxReports, z.cell == selected),
                          ],
                        ),
                        if (_me != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _me!,
                                width: 28,
                                height: 28,
                                child: const _MeMarker(),
                              ),
                            ],
                          ),
                        const RichAttributionWidget(
                          alignment: AttributionAlignment.bottomRight,
                          showFlutterMapAttribution: false,
                          attributions: [
                            TextSourceAttribution(
                              '© OpenStreetMap contributors',
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Filter jenis ancaman
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: _FilterBar(
                        value: ref.watch(threatFilterProvider),
                        onChanged: (k) {
                          ref.read(threatFilterProvider.notifier).select(k);
                          ref.read(selectedCellProvider.notifier).select(null);
                        },
                      ),
                    ),
                    const Positioned(top: 60, left: 12, child: _Legend()),
                    // Kontrol peta
                    Positioned(
                      top: 60,
                      right: 12,
                      child: Column(
                        children: [
                          _MapButton(
                            tooltip: 'Lokasi saya',
                            onPressed: _locateMe,
                            child: _locating
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    size: 20,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          _MapButton(
                            tooltip: 'Kembali ke tampilan awal',
                            onPressed: _resetView,
                            child: const Icon(
                              Icons.center_focus_strong_rounded,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selectedZone != null
                  ? _ZoneCard(
                      key: ValueKey(selectedZone.cell),
                      zone: selectedZone,
                      onClose: () =>
                          ref.read(selectedCellProvider.notifier).select(null),
                    )
                  : _SummaryCard(
                      key: const ValueKey('summary'),
                      zones: zones,
                      onSelect: (z) {
                        ref.read(selectedCellProvider.notifier).select(z.cell);
                        _controller.move(z.center, 13.5);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Polygon _polygonFor(ThreatZone z, int maxReports, bool isSelected) {
    final intensity = z.reports / maxReports;
    final color = ThreatZone.colorFor(intensity);
    return Polygon(
      points: z.boundary,
      color: color.withValues(alpha: 0.3 + intensity * 0.3),
      borderColor: isSelected ? AppColors.textPrimary : color,
      borderStrokeWidth: isSelected ? 3 : 1.5,
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});

  final ThreatKind? value;
  final ValueChanged<ThreatKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            label: 'Semua',
            selected: value == null,
            onTap: () => onChanged(null),
          ),
          for (final k in ThreatKind.values)
            _chip(
              label: k.label,
              selected: value == k,
              onTap: () => onChanged(k),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Rendah', style: theme),
          const SizedBox(width: 6),
          Container(
            width: 44,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [AppColors.warning, AppColors.danger],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('Tinggi', style: theme),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.child,
    required this.onPressed,
    required this.tooltip,
  });

  final Widget child;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: child,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _MeMarker extends StatelessWidget {
  const _MeMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppColors.outline),
);

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({super.key, required this.zones, required this.onSelect});

  final List<ThreatZone> zones;
  final ValueChanged<ThreatZone> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = zones.fold<int>(0, (s, z) => s + z.reports);
    final top = ([
      ...zones,
    ]..sort((a, b) => b.reports.compareTo(a.reports))).take(8).toList();
    final peak = top.isEmpty ? 1 : top.first.reports;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wilayah Aktif', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text('$total Laporan', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  '${zones.length} zona • lokasi dianonimkan (H3)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final z in top)
                  Semantics(
                    button: true,
                    label: 'Zona ${z.kind.label}, ${z.reports} laporan',
                    child: GestureDetector(
                      onTap: () => onSelect(z),
                      child: Container(
                        width: 9,
                        height: (48 * z.reports / peak).clamp(6, 48),
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: ThreatZone.colorFor(z.reports / peak),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
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

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({super.key, required this.zone, required this.onClose});

  final ThreatZone zone;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(zone.kind.icon, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${zone.reports} laporan • ${zone.kind.label}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Terakhir ${timeAgo(zone.lastReportAt).toLowerCase()}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text('H3 ${zone.cell}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
