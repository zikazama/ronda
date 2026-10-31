import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

/// Jenis modus ancaman yang dipetakan.
enum ThreatKind {
  apkScam('APK_SCAM', 'APK Palsu', Icons.android_rounded),
  financialPhishing(
    'FINANCIAL_PHISHING',
    'Phishing Finansial',
    Icons.account_balance_wallet_outlined,
  ),
  impersonation('IMPERSONATION', 'Penyamaran', Icons.badge_outlined),
  suspiciousLink('SUSPICIOUS_LINK', 'Tautan Berbahaya', Icons.link_rounded);

  const ThreatKind(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;

  /// Memetakan `threat_type` hasil deteksi ke kategori peta. Jenis lain
  /// (rekayasa sosial, nomor penipu dikenal) dikelompokkan ke Penyamaran.
  static ThreatKind fromCode(String code) => ThreatKind.values.firstWhere(
    (e) => e.code == code,
    orElse: () => ThreatKind.impersonation,
  );
}

/// Satu sel H3 beserta agregat laporan ancaman (lokasi sudah teranonimkan).
class ThreatZone {
  const ThreatZone({
    required this.cell,
    required this.boundary,
    required this.center,
    required this.reports,
    required this.kind,
    required this.lastReportAt,
  });

  /// Kode sel H3 (hex).
  final String cell;
  final List<LatLng> boundary;
  final LatLng center;
  final int reports;
  final ThreatKind kind;
  final DateTime lastReportAt;

  /// Warna dari kuning (rendah) ke merah (tinggi) berdasarkan intensitas 0..1.
  static Color colorFor(double intensity) =>
      Color.lerp(AppColors.warning, AppColors.danger, intensity.clamp(0, 1))!;
}
