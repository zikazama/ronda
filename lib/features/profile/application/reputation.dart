import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs.dart';

class ReputationLevel {
  const ReputationLevel(this.minPoints, this.name);
  final int minPoints;
  final String name;
}

/// Gamifikasi "Pahlawan Siber": poin dari laporan yang dikirim.
class Reputation {
  const Reputation({required this.points, required this.reports});

  final int points;
  final int reports;

  static const levels = [
    ReputationLevel(0, 'Warga Waspada'),
    ReputationLevel(100, 'Penjaga Lingkungan'),
    ReputationLevel(300, 'Pahlawan Siber'),
    ReputationLevel(700, 'Komandan Ronda'),
    ReputationLevel(1500, 'Legenda Siber'),
  ];

  int get levelIndex {
    var index = 0;
    for (var i = 0; i < levels.length; i++) {
      if (points >= levels[i].minPoints) index = i;
    }
    return index;
  }

  ReputationLevel get level => levels[levelIndex];

  ReputationLevel? get next =>
      levelIndex + 1 < levels.length ? levels[levelIndex + 1] : null;

  /// Progres 0..1 menuju level berikutnya (1 bila sudah maksimal).
  double get progress {
    final n = next;
    if (n == null) return 1;
    final span = n.minPoints - level.minPoints;
    return ((points - level.minPoints) / span).clamp(0.0, 1.0);
  }
}

class ReputationNotifier extends Notifier<Reputation> {
  static const _pointsKey = 'reputation.points';
  static const _reportsKey = 'reputation.reports';

  @override
  Reputation build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return Reputation(
      points: prefs.getInt(_pointsKey) ?? 0,
      reports: prefs.getInt(_reportsKey) ?? 0,
    );
  }

  Future<void> awardReport(int points) async {
    state = Reputation(
      points: state.points + points,
      reports: state.reports + 1,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_pointsKey, state.points);
    await prefs.setInt(_reportsKey, state.reports);
  }
}

final reputationProvider = NotifierProvider<ReputationNotifier, Reputation>(
  ReputationNotifier.new,
);
