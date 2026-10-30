import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

/// Notifikasi mentah yang dikirim engine Kotlin via EventChannel.
class IncomingNotification {
  const IncomingNotification({
    required this.packageName,
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  final String packageName;
  final String sender;
  final String body;
  final int timestamp;

  factory IncomingNotification.fromMap(Map<dynamic, dynamic> map) =>
      IncomingNotification(
        packageName: map['package'] as String? ?? '',
        sender: map['sender'] as String? ?? '',
        body: map['body'] as String? ?? '',
        timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
      );
}

/// Jembatan Flutter <-> Android native (NotificationListenerService & overlay).
///
/// Sisi Kotlin belum diimplementasikan; kelas ini aman dipanggil di platform
/// non-Android (mengembalikan stream kosong / false).
class NativeBridge {
  NativeBridge._();
  static final instance = NativeBridge._();

  static const _events = EventChannel(AppConstants.notificationEventChannel);
  static const _methods = MethodChannel(AppConstants.overlayMethodChannel);

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Stream<IncomingNotification> get notifications {
    if (!_supported) return const Stream.empty();
    return _events
        .receiveBroadcastStream()
        .where((e) => e is Map)
        .map((e) => IncomingNotification.fromMap(e as Map));
  }

  Future<bool> isNotificationAccessGranted() =>
      _invokeBool('isNotificationAccessGranted');
  Future<bool> isOverlayGranted() => _invokeBool('isOverlayGranted');
  Future<void> openNotificationAccessSettings() =>
      _invokeVoid('openNotificationAccessSettings');
  Future<void> openOverlaySettings() => _invokeVoid('openOverlaySettings');

  Future<bool> _invokeBool(String method) async {
    if (!_supported) return false;
    try {
      return await _methods.invokeMethod<bool>(method) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _invokeVoid(String method) async {
    if (!_supported) return;
    try {
      await _methods.invokeMethod<void>(method);
    } on MissingPluginException {
      // Sisi native belum tersedia.
    }
  }
}
