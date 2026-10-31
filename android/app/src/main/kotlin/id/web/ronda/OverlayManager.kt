package id.web.ronda

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

data class OverlayPayload(
    val scanId: String,
    val sender: String,
    val platform: String,
    val title: String,
    val summary: String,
    val confidence: Int,
)

/**
 * Overlay peringatan di atas aplikasi lain (TYPE_APPLICATION_OVERLAY).
 * Dibuat murni dengan View programatik agar tidak bergantung pada tema Activity.
 */
object OverlayManager {
    private val RED = Color.parseColor("#D32F2F")
    private val INK = Color.parseColor("#1B1F2A")
    private val MUTED = Color.parseColor("#5B6475")
    private val SOFT = Color.parseColor("#EEF0F4")

    private var root: View? = null

    fun show(context: Context, payload: OverlayPayload, onAction: (String) -> Unit) {
        dismiss(context)

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val view = build(context, payload) { action ->
            dismiss(context)
            onAction(action)
        }

        @Suppress("DEPRECATION")
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        wm.addView(view, params)
        root = view
    }

    fun dismiss(context: Context) {
        val view = root ?: return
        root = null
        try {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.removeViewImmediate(view)
        } catch (_: Exception) {
        }
    }

    private fun build(context: Context, p: OverlayPayload, onAction: (String) -> Unit): View {
        fun dp(v: Int) = (v * context.resources.displayMetrics.density).toInt()
        fun rounded(color: Int, radiusDp: Int) = GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radiusDp).toFloat()
        }

        fun label(text: String, sizeSp: Float, color: Int, bold: Boolean = false) =
            TextView(context).apply {
                this.text = text
                textSize = sizeSp
                setTextColor(color)
                if (bold) setTypeface(typeface, Typeface.BOLD)
            }

        fun button(text: String, bg: Int, fg: Int, action: String) =
            TextView(context).apply {
                this.text = text
                textSize = 14f
                setTextColor(fg)
                setTypeface(typeface, Typeface.BOLD)
                gravity = Gravity.CENTER
                background = rounded(bg, 14)
                setPadding(dp(12), dp(14), dp(12), dp(14))
                setOnClickListener { onAction(action) }
            }

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(Color.WHITE, 24)
            setPadding(dp(22), dp(22), dp(22), dp(18))
            elevation = dp(8).toFloat()
        }

        card.addView(label("⚠  PERINGATAN RONDA", 12f, RED, bold = true))
        card.addView(
            label(p.title, 19f, INK, bold = true),
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(6) }
        )
        card.addView(
            label(
                listOf(p.platform, p.sender).filter { it.isNotBlank() }.joinToString(" • "),
                13f, MUTED
            ),
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(4) }
        )
        if (p.summary.isNotBlank()) {
            card.addView(
                label(p.summary, 14f, INK),
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = dp(12) }
            )
        }
        card.addView(
            label("Tingkat keyakinan ${p.confidence}%", 12f, MUTED),
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(10) }
        )

        val row = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        row.addView(
            button("Abaikan", SOFT, INK, "dismiss"),
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                .apply { marginEnd = dp(8) }
        )
        row.addView(
            button("Blokir & Laporkan", RED, Color.WHITE, "block"),
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        )
        card.addView(
            row,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(16) }
        )

        return FrameLayout(context).apply {
            setBackgroundColor(Color.parseColor("#99000000"))
            addView(
                card,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    Gravity.CENTER
                ).apply {
                    marginStart = dp(20)
                    marginEnd = dp(20)
                }
            )
        }
    }
}
