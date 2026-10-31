import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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

/// Aksi pengguna pada overlay peringatan.
class OverlayAction {
  const OverlayAction({required this.action, required this.scanId});

  /// `block` (blokir & laporkan) atau `dismiss` (abaikan).
  final String action;
  final String scanId;
}

/// Jembatan Flutter <-> Android native (NotificationListenerService & overlay).
///
/// Aman dipanggil di platform non-Android: stream kosong / hasil `false`.
class NativeBridge {
  NativeBridge._() {
    if (_supported) {
      _methods.setMethodCallHandler(_onNativeCall);
    }
  }
  static final instance = NativeBridge._();

  static const _events = EventChannel(AppConstants.notificationEventChannel);
  static const _methods = MethodChannel(AppConstants.overlayMethodChannel);

  final _actions = StreamController<OverlayAction>.broadcast();

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isSupported => _supported;

  Stream<IncomingNotification> get notifications {
    if (!_supported) return const Stream.empty();
    return _events
        .receiveBroadcastStream()
        .where((e) => e is Map)
        .map((e) => IncomingNotification.fromMap(e as Map));
  }

  Stream<OverlayAction> get overlayActions => _actions.stream;

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'onOverlayAction') {
      final args = call.arguments as Map;
      _actions.add(
        OverlayAction(
          action: args['action'] as String,
          scanId: args['scanId'] as String,
        ),
      );
    }
  }

  // ── Izin ────────────────────────────────────────────────────────────────
  Future<bool> isNotificationAccessGranted() =>
      _invokeBool('isNotificationAccessGranted');
  Future<bool> isOverlayGranted() => _invokeBool('isOverlayGranted');
  Future<void> openNotificationAccessSettings() =>
      _invokeVoid('openNotificationAccessSettings');
  Future<void> openOverlaySettings() => _invokeVoid('openOverlaySettings');

  Future<bool> isContactsGranted() async =>
      _supported && await Permission.contacts.isGranted;

  /// Meminta izin kontak. `true` bila diberikan.
  Future<bool> requestContacts() async {
    if (!_supported) return false;
    final status = await Permission.contacts.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    return status.isGranted;
  }

  // ── Overlay ─────────────────────────────────────────────────────────────
  /// Menampilkan overlay peringatan. `false` bila izin overlay belum ada
  /// atau platform tak didukung.
  Future<bool> showOverlay({
    required String scanId,
    required String sender,
    required String platformLabel,
    required String title,
    required String summary,
    required int confidencePercent,
    required bool playAlarm,
  }) => _invokeBool('showOverlay', {
    'scanId': scanId,
    'sender': sender,
    'platform': platformLabel,
    'title': title,
    'summary': summary,
    'confidence': confidencePercent,
    'playAlarm': playAlarm,
  });

  Future<void> dismissOverlay() => _invokeVoid('dismissOverlay');

  Future<bool> _invokeBool(String method, [Object? args]) async {
    if (!_supported) return false;
    try {
      return await _methods.invokeMethod<bool>(method, args) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('NativeBridge.$method gagal: ${e.message}');
      return false;
    }
  }

  Future<void> _invokeVoid(String method, [Object? args]) async {
    if (!_supported) return;
    try {
      await _methods.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Sisi native belum tersedia.
    } on PlatformException catch (e) {
      debugPrint('NativeBridge.$method gagal: ${e.message}');
    }
  }
}
