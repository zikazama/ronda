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

  static MessagePlatform parse(String value) => MessagePlatform.values
      .firstWhere((e) => e.name == value, orElse: () => MessagePlatform.sms);

  /// Memetakan nama paket Android ke platform. `null` bila tidak dipantau.
  static MessagePlatform? fromPackage(String packageName) =>
      switch (packageName) {
        'com.google.android.apps.messaging' ||
        'com.android.mms' ||
        'com.samsung.android.messaging' => sms,
        'com.whatsapp' || 'com.whatsapp.w4b' => whatsapp,
        'org.telegram.messenger' => telegram,
        'jp.naver.line.android' => line,
        'com.facebook.orca' => messenger,
        'com.instagram.android' => instagram,
        _ => null,
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

  Map<String, dynamic> toJson() => {
    'bank_account': bankAccount,
    'file_extension': fileExtension,
    'suspicious_url': suspiciousUrl,
  };

  /// Gabungkan: nilai milik `this` diutamakan, sisanya diisi [other].
  ExtractedEntities merge(ExtractedEntities other) => ExtractedEntities(
    bankAccount: bankAccount ?? other.bankAccount,
    fileExtension: fileExtension ?? other.fileExtension,
    suspiciousUrl: suspiciousUrl ?? other.suspiciousUrl,
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
    this.decidedByLayer = 0,
    this.latencyMs = 0,
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

  /// Lapis pipeline (1-4) yang memutuskan hasil; 0 = tidak diketahui.
  final int decidedByLayer;
  final int latencyMs;

  bool get showsOverlay => actionRequired.startsWith('SHOW_POPUP_ALERT');

  /// Disimpan lokal. Isi pesan SENGAJA tidak disimpan (privacy by design).
  Map<String, dynamic> toStoredJson() => {
    'scan_id': scanId,
    'platform': platform.name,
    'sender': sender,
    'risk_level': riskLevel.name,
    'threat_type': threatType,
    'confidence_score': confidenceScore,
    'ai_summary': aiSummary,
    'extracted_entities': entities.toJson(),
    'action_required': actionRequired,
    'scanned_at': scannedAt.millisecondsSinceEpoch,
    'decided_by_layer': decidedByLayer,
    'latency_ms': latencyMs,
  };

  factory ScanResult.fromStoredJson(Map<String, dynamic> json) => ScanResult(
    scanId: json['scan_id'] as String,
    platform: MessagePlatform.parse(json['platform'] as String),
    sender: json['sender'] as String,
    riskLevel: RiskLevel.parse(json['risk_level'] as String),
    threatType: json['threat_type'] as String,
    confidenceScore: (json['confidence_score'] as num).toDouble(),
    aiSummary: json['ai_summary'] as String,
    entities: ExtractedEntities.fromJson(
      json['extracted_entities'] as Map<String, dynamic>,
    ),
    actionRequired: json['action_required'] as String,
    scannedAt: DateTime.fromMillisecondsSinceEpoch(json['scanned_at'] as int),
    decidedByLayer: json['decided_by_layer'] as int? ?? 0,
    latencyMs: json['latency_ms'] as int? ?? 0,
  );

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
