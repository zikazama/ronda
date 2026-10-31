import '../cloud/cloud_gateway.dart';
import '../../features/scan/domain/scan_result.dart';

class SpamEntry {
  const SpamEntry({
    required this.key,
    required this.reportCount,
    required this.riskLevel,
    required this.aiSummary,
  });

  final String key;
  final int reportCount;
  final RiskLevel riskLevel;
  final String aiSummary;
}

/// Dilempar saat basis data tak terjangkau (luring / Firebase belum diatur).
/// Dibedakan dari "tidak ditemukan" agar Bloom Filter tidak salah dianggap
/// false positive.
class SpamDirectoryUnavailable implements Exception {
  const SpamDirectoryUnavailable();

  @override
  String toString() => 'Direktori spam tidak tersedia';
}

/// Lapis 2 — basis data laporan komunitas (`spam_summaries`).
abstract interface class SpamDirectory {
  /// `null` bila nomor belum pernah dilaporkan.
  /// Melempar [SpamDirectoryUnavailable] (atau error jaringan/timeout) bila
  /// basis data tak dapat dihubungi.
  Future<SpamEntry?> lookup(String key);

  /// Nomor paling sering dilaporkan, untuk mengisi Bloom Filter luring.
  /// Kosong bila tak tersedia.
  Future<List<String>> topSpamKeys({int limit = 500});
}

class FirestoreSpamDirectory implements SpamDirectory {
  FirestoreSpamDirectory(this._gateway);

  final CloudGateway _gateway;

  static const _timeout = Duration(milliseconds: 1500);

  @override
  Future<SpamEntry?> lookup(String key) async {
    final cloud = await _gateway.servicesQuick();
    if (cloud == null) throw const SpamDirectoryUnavailable();

    final doc = await cloud.firestore
        .collection('spam_summaries')
        .doc(key)
        .get()
        .timeout(_timeout);
    final data = doc.data();
    if (data == null) return null;

    return SpamEntry(
      key: key,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      riskLevel: RiskLevel.parse(data['riskLevel'] as String? ?? 'HIGH'),
      aiSummary: data['aiSummary'] as String? ?? '',
    );
  }

  @override
  Future<List<String>> topSpamKeys({int limit = 500}) async {
    final cloud = await _gateway.services();
    if (cloud == null) return const [];

    final snap = await cloud.firestore
        .collection('spam_summaries')
        .orderBy('reportCount', descending: true)
        .limit(limit)
        .get()
        .timeout(const Duration(seconds: 15));

    return snap.docs
        .where((d) => (d.data()['reportCount'] as num? ?? 0) >= 3)
        .map((d) => d.id)
        .toList(growable: false);
  }
}
