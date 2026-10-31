package id.web.ronda

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Peringatan multi-sensori: alarm bila ponsel mode normal, getar bila
 * senyap/getar (agar tidak mengganggu saat rapat/ibadah).
 */
object AlertPlayer {
    private const val ALARM_MS = 6_000L
    private val PATTERN = longArrayOf(0, 500, 200, 500, 200, 800)

    private val handler = Handler(Looper.getMainLooper())
    private var ringtone: Ringtone? = null

    fun alert(context: Context) {
        stop()
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (audio.ringerMode == AudioManager.RINGER_MODE_NORMAL) {
            playAlarm(context)
        } else {
            vibrate(context)
        }
    }

    fun stop() {
        handler.removeCallbacksAndMessages(null)
        try {
            ringtone?.stop()
        } catch (_: Exception) {
        }
        ringtone = null
    }

    private fun playAlarm(context: Context) {
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: return
        val r = RingtoneManager.getRingtone(context, uri) ?: return
        r.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        r.play()
        ringtone = r
        handler.postDelayed({ stop() }, ALARM_MS)
    }

    @Suppress("DEPRECATION")
    private fun vibrate(context: Context) {
        val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
        if (vibrator == null || !vibrator.hasVibrator()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(PATTERN, -1))
        } else {
            vibrator.vibrate(PATTERN, -1)
        }
    }
}
