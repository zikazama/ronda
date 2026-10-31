package id.web.ronda

import android.app.Notification
import android.content.ComponentName
import android.os.Build
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Membaca notifikasi aplikasi pesan lalu meneruskannya ke pipeline deteksi
 * (Dart) lewat [Bridge]. Hanya teks notifikasi yang dibaca; tidak ada
 * akses ke isi aplikasi pesan itu sendiri.
 *
 * Pesan dari kontak yang tersimpan dilewati di sini, sehingga tidak pernah
 * sampai ke lapisan analisis (privasi + hemat kuota).
 */
class RondaNotificationListener : NotificationListenerService() {

    private var lastSignature: String? = null
    private var lastSignatureAt = 0L

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            handle(sbn)
        } catch (e: Exception) {
            // Jangan pernah membuat listener crash karena satu notifikasi aneh.
            Log.w(TAG, "Gagal memproses notifikasi", e)
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        // Minta sistem menyambungkan ulang agar proteksi tidak mati diam-diam.
        try {
            requestRebind(ComponentName(this, RondaNotificationListener::class.java))
        } catch (e: Exception) {
            Log.w(TAG, "Gagal rebind", e)
        }
    }

    private fun handle(sbn: StatusBarNotification) {
        if (sbn.packageName !in WATCHED_PACKAGES) return

        val notification = sbn.notification ?: return
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = notification.extras ?: return
        val (sender, body) = extractLatest(extras) ?: return
        if (body.isBlank() || sender.isBlank()) return
        if (SUMMARY_PATTERN.containsMatchIn(body)) return

        // Notifikasi yang sama sering diposting ulang (update progress, dll.).
        val signature = "${sbn.packageName}|$sender|$body"
        val now = System.currentTimeMillis()
        if (signature == lastSignature && now - lastSignatureAt < DEDUPE_MS) return
        lastSignature = signature
        lastSignatureAt = now

        if (ContactChecker.isSavedContact(applicationContext, sender)) return

        Bridge.emit(
            mapOf(
                "package" to sbn.packageName,
                "sender" to sender,
                "body" to body,
                "timestamp" to sbn.postTime,
            )
        )
    }

    /**
     * Mengambil (pengirim, teks) PESAN TERBARU.
     * Aplikasi chat memakai MessagingStyle: EXTRA_MESSAGES berisi riwayat
     * pesan, bukan hanya yang terakhir.
     */
    @Suppress("DEPRECATION")
    private fun extractLatest(extras: Bundle): Pair<String, String>? {
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()

        val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
        val last = messages?.lastOrNull() as? Bundle
        val messageText = last?.getCharSequence("text")?.toString()
        if (last != null && !messageText.isNullOrBlank()) {
            var sender = last.getCharSequence("sender")?.toString()
            if (sender.isNullOrBlank() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                sender = (last.get("sender_person") as? android.app.Person)?.name?.toString()
            }
            val name = if (sender.isNullOrBlank()) title else sender
            return if (name.isNullOrBlank()) null else name to messageText
        }

        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()
        if (title.isNullOrBlank() || text.isNullOrBlank()) return null
        return title to text
    }

    companion object {
        private const val TAG = "RondaListener"
        private const val DEDUPE_MS = 3_000L

        /** Aplikasi yang dipantau (WhatsApp, Telegram, SMS, dll.). */
        val WATCHED_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "org.telegram.messenger.web",
            "org.thunderdog.challegram",
            "com.google.android.apps.messaging",
            "com.android.mms",
            "com.samsung.android.messaging",
            "com.facebook.orca",
            "com.instagram.android",
            "jp.naver.line.android",
            "com.truecaller",
        )

        // "3 pesan baru", "2 new messages", "Memeriksa pesan baru", dst.
        private val SUMMARY_PATTERN = Regex(
            "^\\d+\\s+(new\\s+)?(messages?|pesan)(\\s+baru)?|" +
                "checking for new messages|memeriksa pesan",
            RegexOption.IGNORE_CASE
        )
    }
}
