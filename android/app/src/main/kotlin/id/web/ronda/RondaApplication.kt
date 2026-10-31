package id.web.ronda

import android.app.Application
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Menyalakan satu FlutterEngine saat proses dimulai dan menyimpannya di cache.
 *
 * Alasannya: NotificationListenerService hidup di proses yang sama dengan
 * aplikasi. Dengan engine yang dibuat di sini, pipeline deteksi (Dart) sudah
 * berjalan ketika notifikasi masuk, walau Activity belum/tidak sedang dibuka.
 * MainActivity memakai engine yang sama (lihat [MainActivity]).
 */
class RondaApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(this)
        loader.ensureInitializationComplete(this, null)

        // Plugin (Firebase, geolocator, dll.) terdaftar otomatis oleh konstruktor ini.
        val engine = FlutterEngine(this)

        // Channel harus siap SEBELUM Dart berjalan agar main() bisa langsung
        // mendengarkan notifikasi.
        Bridge.attach(this, engine.dartExecutor.binaryMessenger)

        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }

    companion object {
        const val ENGINE_ID = "ronda_engine"
    }
}
