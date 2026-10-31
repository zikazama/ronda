import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/cloud/cloud_gateway.dart';
import '../../heatmap/domain/threat_zone.dart';
import '../../scan/domain/scan_result.dart';

/// Mengirim laporan komunitas ke Firestore (paket gratis Spark, tanpa
/// Cloud Functions). Integritas data dijaga oleh `firestore.rules`:
/// satu laporan per pengguna per nomor, dan agregat hanya boleh naik +1
/// bersamaan dengan laporan tersebut.
class CommunityReporter {
  CommunityReporter(this._gateway);

  final CloudGateway _gateway;

  /// Mengembalikan `true` bila batch diterima server. Saat luring, penulisan
  /// diantre oleh Firestore dan dikirim ketika koneksi pulih; fungsi ini
  /// berhenti menunggu setelah [wait].
  Future<bool> submit({
    required String suspectKey,
    required ScanResult scan,
    String? h3Cell,
    Duration wait = const Duration(seconds: 4),
  }) async {
    final cloud = await _gateway.servicesQuick(
      wait: const Duration(seconds: 3),
    );
    if (cloud == null) return false;

    final fs = cloud.firestore;
    final summary = _clip(scan.aiSummary, 280);
    final kind = ThreatKind.fromCode(scan.threatType);
    final now = FieldValue.serverTimestamp();

    final batch = fs.batch();
    batch.set(fs.collection('user_reports').doc('${cloud.uid}_$suspectKey'), {
      'uid': cloud.uid,
      'suspectKey': suspectKey,
      'platform': scan.platform.name,
      'threatType': kind.code,
      'description': summary,
      'h3Location': h3Cell,
      'createdAt': now,
    });
    batch.set(fs.collection('spam_summaries').doc(suspectKey), {
      'reportCount': FieldValue.increment(1),
      'riskLevel': 'HIGH',
      'aiSummary': summary,
      'threatType': kind.code,
      'lastUpdated': now,
    }, SetOptions(merge: true));
    if (h3Cell != null) {
      batch.set(fs.collection('threat_cells').doc('${h3Cell}_${kind.code}'), {
        'cell': h3Cell,
        'kind': kind.code,
        'reports': FieldValue.increment(1),
        'lastReportAt': now,
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit().timeout(wait);
      return true;
    } on Object {
      // Timeout/luring: penulisan tetap diantre di cache Firestore.
      return false;
    }
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}
