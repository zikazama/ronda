package id.web.ronda

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Jembatan Kotlin <-> Dart.
 *
 * - EventChannel `notifications`: notifikasi masuk (dari listener) ke Dart.
 * - MethodChannel `overlay`: cek/minta izin, tampilkan overlay; Dart menerima
 *   aksi pengguna lewat `onOverlayAction`.
 *
 * Nama channel HARUS sama dengan `AppConstants` di Dart.
 */
object Bridge {
    private const val EVENTS = "id.web.ronda/notifications"
    private const val METHODS = "id.web.ronda/overlay"
    private const val MAX_PENDING = 20

    private val main = Handler(Looper.getMainLooper())
    private lateinit var appContext: Context

    private var sink: EventChannel.EventSink? = null
    private val pending = ArrayDeque<Map<String, Any?>>()
    private var methods: MethodChannel? = null

    fun attach(context: Context, messenger: BinaryMessenger) {
        appContext = context.applicationContext

        EventChannel(messenger, EVENTS).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                sink = events
                flushPending()
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })

        methods = MethodChannel(messenger, METHODS).also {
            it.setMethodCallHandler { call, result -> onMethod(call, result) }
        }
    }

    /** Kirim notifikasi ke Dart. Disangga bila Dart belum mendengarkan. */
    fun emit(payload: Map<String, Any?>) {
        main.post {
            val s = sink
            if (s != null) {
                s.success(payload)
            } else {
                if (pending.size >= MAX_PENDING) pending.removeFirst()
                pending.addLast(payload)
            }
        }
    }

    private fun flushPending() {
        val s = sink ?: return
        while (pending.isNotEmpty()) s.success(pending.removeFirst())
    }

    private fun onMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isNotificationAccessGranted" -> result.success(isNotificationAccessGranted())
            "isOverlayGranted" -> result.success(Settings.canDrawOverlays(appContext))
            "openNotificationAccessSettings" -> {
                launch(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                result.success(null)
            }
            "openOverlaySettings" -> {
                launch(
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${appContext.packageName}")
                    )
                )
                result.success(null)
            }
            "showOverlay" -> result.success(showOverlay(call))
            "dismissOverlay" -> {
                OverlayManager.dismiss(appContext)
                AlertPlayer.stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun showOverlay(call: MethodCall): Boolean {
        if (!Settings.canDrawOverlays(appContext)) return false

        val scanId = call.argument<String>("scanId") ?: return false
        val payload = OverlayPayload(
            scanId = scanId,
            sender = call.argument<String>("sender") ?: "",
            platform = call.argument<String>("platform") ?: "",
            title = call.argument<String>("title") ?: "Pesan berbahaya",
            summary = call.argument<String>("summary") ?: "",
            confidence = call.argument<Int>("confidence") ?: 0,
        )

        OverlayManager.show(appContext, payload) { action ->
            AlertPlayer.stop()
            methods?.invokeMethod("onOverlayAction", mapOf("action" to action, "scanId" to scanId))
        }
        if (call.argument<Boolean>("playAlarm") != false) AlertPlayer.alert(appContext)
        return true
    }

    private fun isNotificationAccessGranted(): Boolean {
        val flat = Settings.Secure.getString(
            appContext.contentResolver, "enabled_notification_listeners"
        ) ?: return false
        return flat.split(":").any {
            ComponentName.unflattenFromString(it)?.packageName == appContext.packageName
        }
    }

    private fun launch(intent: Intent) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        appContext.startActivity(intent)
    }
}
