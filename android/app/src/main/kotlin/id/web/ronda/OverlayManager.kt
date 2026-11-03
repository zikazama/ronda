package id.web.ronda

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.accessibility.AccessibilityNodeInfo
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
    val advice: String = "",
)

/**
 * Overlay peringatan di atas aplikasi lain (TYPE_APPLICATION_OVERLAY).
 * Dibuat murni dengan View programatik agar tidak bergantung pada tema Activity.
 *
 * Kartu berada di bawah layar (terjangkau satu tangan), tombol berukuran
 * sentuh >= 52dp, dan tombol Back sama dengan "Abaikan".
 */
object OverlayManager {
    private val RED = Color.parseColor("#D6343B")
    private val RED_SOFT = Color.parseColor("#FCE9EA")
    private val INK = Color.parseColor("#0D1B34")
    private val MUTED = Color.parseColor("#45546B")
    private val SOFT = Color.parseColor("#EAEEF5")

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
        // Agar tombol Back diterima dan TalkBack langsung membacakan peringatan.
        view.requestFocus()
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

    /** Font yang sama dengan aplikasi (aset Flutter). Gagal => font sistem. */
    private fun font(context: Context, weight: Int): Typeface? = try {
        Typeface.createFromAsset(
            context.assets, "flutter_assets/assets/fonts/PlusJakartaSans-$weight.ttf"
        )
    } catch (_: Exception) {
        null
    }

    private fun build(context: Context, p: OverlayPayload, onAction: (String) -> Unit): View {
        fun dp(v: Int) = (v * context.resources.displayMetrics.density).toInt()
        fun rounded(color: Int, radiusDp: Int) = GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radiusDp).toFloat()
        }

        val regular = font(context, 500)
        val semibold = font(context, 600)
        val bold = font(context, 800)

        fun label(text: String, sizeSp: Float, color: Int, face: Typeface? = regular) =
            TextView(context).apply {
                this.text = text
                textSize = sizeSp
                setTextColor(color)
                setLineSpacing(0f, 1.15f)
                if (face != null) typeface = face
            }

        fun lp(topDp: Int = 0) = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(topDp) }

        fun button(text: String, bg: Int, fg: Int, action: String, description: String) =
            TextView(context).apply {
                this.text = text
                textSize = 15f
                setTextColor(fg)
                typeface = bold ?: Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                minHeight = dp(52)
                background = rounded(bg, 12)
                setPadding(dp(12), dp(14), dp(12), dp(14))
                isClickable = true
                isFocusable = true
                contentDescription = description
                setOnClickListener { onAction(action) }
                // TalkBack membacakannya sebagai tombol.
                accessibilityDelegate = object : View.AccessibilityDelegate() {
                    override fun onInitializeAccessibilityNodeInfo(
                        host: View, info: AccessibilityNodeInfo
                    ) {
                        super.onInitializeAccessibilityNodeInfo(host, info)
                        info.className = "android.widget.Button"
                    }
                }
            }

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(Color.WHITE, 20)
            setPadding(dp(20), dp(20), dp(20), dp(16))
            elevation = dp(8).toFloat()
            accessibilityLiveRegion = View.ACCESSIBILITY_LIVE_REGION_ASSERTIVE
        }

        // Penanda risiko: lingkaran merah + kalimat biasa (bukan huruf kapital).
        val header = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        header.addView(
            TextView(context).apply {
                text = "!"
                textSize = 16f
                setTextColor(Color.WHITE)
                typeface = bold ?: Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(RED)
                }
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            },
            LinearLayout.LayoutParams(dp(28), dp(28)).apply { marginEnd = dp(10) }
        )
        header.addView(label("Pesan berbahaya terdeteksi", 13f, RED, semibold))
        card.addView(header, lp())

        card.addView(label(p.title, 21f, INK, bold), lp(10))
        card.addView(
            label(
                listOf(p.platform, p.sender).filter { it.isNotBlank() }.joinToString(" dari "),
                13.5f, MUTED, semibold
            ),
            lp(4)
        )
        if (p.summary.isNotBlank()) {
            card.addView(label(p.summary, 14.5f, INK), lp(12))
        }
        if (p.advice.isNotBlank()) {
            card.addView(
                label(p.advice, 14f, INK, semibold).apply {
                    background = rounded(RED_SOFT, 12)
                    setPadding(dp(14), dp(12), dp(14), dp(12))
                },
                lp(14)
            )
        }
        card.addView(label("Tingkat keyakinan ${p.confidence}%", 12f, MUTED), lp(10))

        val row = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL }
        row.addView(
            button("Abaikan", SOFT, INK, "dismiss", "Abaikan peringatan"),
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                .apply { marginEnd = dp(10) }
        )
        row.addView(
            button("Blokir & laporkan", RED, Color.WHITE, "block", "Blokir dan laporkan nomor ini"),
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.25f)
        )
        card.addView(row, lp(16))

        return FrameLayout(context).apply {
            setBackgroundColor(Color.parseColor("#B3000000"))
            isFocusable = true
            isFocusableInTouchMode = true
            setOnKeyListener { _, keyCode, event ->
                if (keyCode == KeyEvent.KEYCODE_BACK && event.action == KeyEvent.ACTION_UP) {
                    onAction("dismiss")
                    true
                } else false
            }
            addView(
                card,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    Gravity.BOTTOM
                ).apply {
                    marginStart = dp(12)
                    marginEnd = dp(12)
                    bottomMargin = dp(28)
                }
            )
        }
    }
}
