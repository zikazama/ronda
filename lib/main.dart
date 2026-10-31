import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/detection/detection_service.dart';
import 'core/storage/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Proteksi dimulai SEBELUM UI. Di Android, engine Flutter di-cache oleh
  // RondaApplication dan dijalankan saat NotificationListenerService aktif,
  // jadi deteksi tetap berjalan walau layar aplikasi belum/tidak terbuka.
  container.read(detectionServiceProvider).start();

  _runWhenViewAvailable(
    UncontrolledProviderScope(container: container, child: const RondaApp()),
  );
}

/// `runApp` butuh view. Pada engine tanpa layar (listener aktif sementara
/// Activity belum dibuka) view belum ada, jadi tunggu sampai tersedia.
void _runWhenViewAvailable(Widget app) {
  if (PlatformDispatcher.instance.implicitView != null) {
    runApp(app);
    return;
  }
  final waiter = _ViewWaiter();
  waiter.onReady = () {
    WidgetsBinding.instance.removeObserver(waiter);
    runApp(app);
  };
  WidgetsBinding.instance.addObserver(waiter);
}

class _ViewWaiter with WidgetsBindingObserver {
  late final VoidCallback onReady;
  bool _fired = false;

  @override
  void didChangeMetrics() {
    if (_fired || PlatformDispatcher.instance.implicitView == null) return;
    _fired = true;
    onReady();
  }
}
