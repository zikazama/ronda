import '../../../core/constants/app_constants.dart';
import '../../../core/detection/number_utils.dart';
import '../../../core/detection/threat_list_store.dart';
import '../../../core/geo/geo_index.dart';
import '../../../core/geo/location_service.dart';
import '../../profile/application/reputation.dart';
import '../../scan/domain/scan_result.dart';
import 'community_reporter.dart';

enum ReportOutcome {
  /// Ditandai di perangkat dan terkirim ke komunitas.
  reported,

  /// Ditandai di perangkat; pengiriman diantre (luring) atau Firebase nonaktif.
  markedLocally,

  /// Sudah pernah ditandai sebelumnya.
  alreadyReported,
}

/// "Blokir Nomor": menandai pengirim sebagai penipu di perangkat (Lapis 1),
/// melaporkannya ke komunitas, dan memberi poin reputasi.
class ReportService {
  ReportService({
    required this._store,
    required this._reporter,
    required this._reputation,
    required this._location,
    required this._geo,
  });

  final ThreatListStore _store;
  final CommunityReporter _reporter;
  final ReputationNotifier _reputation;
  final LocationService _location;
  final GeoIndex Function() _geo;

  Future<ReportOutcome> report(ScanResult scan) async {
    final key = senderKey(scan.sender);
    if (_store.isBlocked(key)) return ReportOutcome.alreadyReported;

    await _store.block(key);
    await _reputation.awardReport(AppConstants.pointsPerReport);

    // Lokasi dianonimkan menjadi sel H3 (resolusi 8, ±0,7 km²).
    String? cell;
    final point = await _location.currentIfPermitted();
    if (point != null) {
      try {
        cell = _geo().cellOf(point);
      } on Object {
        cell = null;
      }
    }

    final sent = await _reporter.submit(
      suspectKey: key,
      scan: scan,
      h3Cell: cell,
    );
    return sent ? ReportOutcome.reported : ReportOutcome.markedLocally;
  }
}
