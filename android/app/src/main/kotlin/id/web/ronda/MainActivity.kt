package id.web.ronda

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

/** Memakai engine yang dibuat [RondaApplication] dan tidak menghancurkannya saat ditutup. */
class MainActivity : FlutterActivity() {

    override fun provideFlutterEngine(context: Context): FlutterEngine? =
        FlutterEngineCache.getInstance().get(RondaApplication.ENGINE_ID)

    // Engine harus tetap hidup agar proteksi berjalan setelah Activity ditutup.
    override fun shouldDestroyEngineWithHost(): Boolean = false
}
