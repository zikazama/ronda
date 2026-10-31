import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/prefs.dart';
import '../domain/scan_result.dart';

/// Riwayat deteksi berisiko (MEDIUM/HIGH), tersimpan lokal. Isi pesan tidak
/// pernah disimpan.
class ScanHistoryNotifier extends Notifier<List<ScanResult>> {
  static const _key = 'history.scans';

  @override
  List<ScanResult> build() {
    final raw = ref.read(sharedPreferencesProvider).getStringList(_key);
    if (raw == null) return const [];
    final out = <ScanResult>[];
    for (final item in raw) {
      try {
        out.add(
          ScanResult.fromStoredJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } on Object catch (e) {
        debugPrint('Entri riwayat rusak dilewati: $e');
      }
    }
    return out;
  }

  Future<void> add(ScanResult result) async {
    state = [
      result,
      ...state,
    ].take(AppConstants.historyLimit).toList(growable: false);
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }

  Future<void> _persist() => ref
      .read(sharedPreferencesProvider)
      .setStringList(
        _key,
        state.map((e) => jsonEncode(e.toStoredJson())).toList(),
      );
}

final scanHistoryProvider =
    NotifierProvider<ScanHistoryNotifier, List<ScanResult>>(
      ScanHistoryNotifier.new,
    );

/// Jumlah seluruh pesan yang pernah dipindai (termasuk yang aman).
class ScannedCountNotifier extends Notifier<int> {
  static const _key = 'stats.scanned';

  @override
  int build() => ref.read(sharedPreferencesProvider).getInt(_key) ?? 0;

  Future<void> increment() async {
    state = state + 1;
    await ref.read(sharedPreferencesProvider).setInt(_key, state);
  }
}

final scannedCountProvider = NotifierProvider<ScannedCountNotifier, int>(
  ScannedCountNotifier.new,
);

/// Jumlah ancaman (risiko MEDIUM/HIGH) pada riwayat.
final threatCountProvider = Provider<int>(
  (ref) => ref
      .watch(scanHistoryProvider)
      .where((e) => e.riskLevel != RiskLevel.low)
      .length,
);
