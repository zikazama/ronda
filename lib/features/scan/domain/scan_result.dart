import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum MessagePlatform {
  sms,
  whatsapp,
  telegram,
  line,
  messenger,
  instagram;

  String get label => switch (this) {
    sms => 'SMS',
    whatsapp => 'WhatsApp',
    telegram => 'Telegram',
    line => 'LINE',
    messenger => 'Messenger',
    instagram => 'Instagram',
  };
}

enum RiskLevel {
  low,
  medium,
  high;

  static RiskLevel parse(String value) => RiskLevel.values.firstWhere(
    (e) => e.name == value.toLowerCase(),
    orElse: () => RiskLevel.low,
  );

  String get label => switch (this) {
    low => 'Aman',
    medium => 'Waspada',
    high => 'Bahaya',
  };

  Color get color => switch (this) {
    low => AppColors.safe,
    medium => AppColors.warning,
    high => AppColors.danger,
  };

  Color get softColor => switch (this) {
    low => AppColors.safeSoft,
    medium => AppColors.warningSoft,
    high => AppColors.dangerSoft,
  };

  IconData get icon => switch (this) {
    low => Icons.verified_user_rounded,
    medium => Icons.warning_amber_rounded,
    high => Icons.gpp_bad_rounded,
  };
}

/// Entitas yang diekstrak dari pesan (rekening, ekstensi file, URL).
class ExtractedEntities {
  const ExtractedEntities({
    this.bankAccount,
    this.fileExtension,
    this.suspiciousUrl,
  });

  final String? bankAccount;
  final String? fileExtension;
  final String? suspiciousUrl;

  factory ExtractedEntities.fromJson(Map<String, dynamic> json) =>
      ExtractedEntities(
        bankAccount: json['bank_account'] as String?,
        fileExtension: json['file_extension'] as String?,
        suspiciousUrl: json['suspicious_url'] as String?,
      );
}

/// Respons `POST /api/v1/notifications/scan`.
class ScanResult {
  const ScanResult({
    required this.scanId,
    required this.platform,
    required this.sender,
    required this.riskLevel,
    required this.threatType,
    required this.confidenceScore,
    required this.aiSummary,
    required this.entities,
    required this.actionRequired,
    required this.scannedAt,
  });

  final String scanId;
  final MessagePlatform platform;
  final String sender;
  final RiskLevel riskLevel;
  final String threatType;
  final double confidenceScore;
  final String aiSummary;
  final ExtractedEntities entities;
  final String actionRequired;
  final DateTime scannedAt;

  bool get showsOverlay => actionRequired.startsWith('SHOW_POPUP_ALERT');

  factory ScanResult.fromJson(
    Map<String, dynamic> json, {
    required MessagePlatform platform,
    required String sender,
    DateTime? scannedAt,
  }) => ScanResult(
    scanId: json['scan_id'] as String,
    platform: platform,
    sender: sender,
    riskLevel: RiskLevel.parse(json['risk_level'] as String),
    threatType: json['threat_type'] as String,
    confidenceScore: (json['confidence_score'] as num).toDouble(),
    aiSummary: json['ai_summary'] as String,
    entities: ExtractedEntities.fromJson(
      json['extracted_entities'] as Map<String, dynamic>,
    ),
    actionRequired: json['action_required'] as String,
    scannedAt: scannedAt ?? DateTime.now(),
  );
}
