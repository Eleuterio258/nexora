package tech.e258tech.nexora_mobile.ui.tabs

import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.View
import android.view.Gravity
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.ui.screens.main.BaseTabActivity

internal data class PageRow(val title: String, val subtitle: String, val value: String)

internal fun BaseTabActivity.renderListPage(title: String, subtitle: String, rows: List<PageRow>) {
    binding.mainContent.setPadding(0, 0, 0, dp(78) + currentBottomInset)
    binding.mainContent.removeAllViews()
    binding.mainContent.addView(buildPageTitle(title, subtitle))
    binding.mainContent.addRowsWithDividers(rows)
}

internal fun BaseTabActivity.buildPageTitle(title: String, subtitle: String): LinearLayout =
    LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(20), dp(24), dp(20), dp(8))
        addView(textView(title, 24f, R.color.text_primary, bold = true))
        addView(textView(subtitle, 14f, R.color.text_secondary).apply {
            setPadding(0, dp(6), 0, 0)
        })
    }

internal fun BaseTabActivity.buildPageCard(row: PageRow): LinearLayout =
    buildActionRow(
        title = row.title,
        subtitle = row.subtitle,
        value = row.value,
        iconRes = android.R.drawable.ic_menu_info_details,
    )

internal fun BaseTabActivity.buildActionRow(
    title: String,
    subtitle: String,
    value: String? = null,
    iconRes: Int,
    iconColor: Int = getColor(R.color.primary_blue),
    onClick: (() -> Unit)? = null,
): LinearLayout {
    val rippleValue = android.util.TypedValue()
    theme.resolveAttribute(android.R.attr.selectableItemBackground, rippleValue, true)

    return LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(16), dp(14), dp(16), dp(14))
        background = ContextCompat.getDrawable(context, rippleValue.resourceId)
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { setMargins(dp(16), dp(8), dp(16), dp(8)) }

        addView(ImageView(context).apply {
            setImageResource(iconRes)
            setColorFilter(iconColor)
            layoutParams = LinearLayout.LayoutParams(dp(36), dp(36)).apply {
                marginEnd = dp(12)
            }
            setPadding(dp(6), dp(6), dp(6), dp(6))
        })

        addView(LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            addView(textView(title, 15f, R.color.text_primary, bold = true))
            addView(textView(subtitle, 12f, R.color.text_secondary).apply {
                setPadding(0, dp(4), 0, 0)
            })
        })

        if (value.isNullOrBlank()) {
            addView(ImageView(context).apply {
                setImageResource(android.R.drawable.ic_media_next)
                setColorFilter(getColor(R.color.text_hint))
                layoutParams = LinearLayout.LayoutParams(dp(24), dp(24))
                setPadding(dp(5), dp(5), dp(5), dp(5))
            })
        } else {
            addView(textView(value, 12f, R.color.primary_blue, bold = true).apply {
                gravity = Gravity.CENTER
                setPadding(dp(8), dp(4), dp(8), dp(4))
            })
        }

        onClick?.let { listener ->
            isClickable = true
            isFocusable = true
            setOnClickListener { listener() }
        }
    }
}

internal fun BaseTabActivity.buildElevatedPageCard(row: PageRow): LinearLayout =
    LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(16), dp(14), dp(16), dp(14))
        background = GradientDrawable().apply {
            setColor(getColor(R.color.white))
            cornerRadius = dp(12).toFloat()
        }
        elevation = dp(2).toFloat()
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { setMargins(dp(16), dp(8), dp(16), dp(8)) }

        addView(LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            addView(textView(row.title, 15f, R.color.text_primary, bold = true))
            addView(textView(row.subtitle, 12f, R.color.text_secondary).apply {
                setPadding(0, dp(4), 0, 0)
            })
        })

        addView(textView(row.value, 12f, R.color.primary_blue, bold = true).apply {
            gravity = Gravity.CENTER
            setPadding(dp(10), dp(6), dp(10), dp(6))
            background = GradientDrawable().apply {
                setColor(getColor(R.color.background))
                cornerRadius = dp(16).toFloat()
            }
        })
    }

internal fun LinearLayout.addRowsWithDividers(rows: List<PageRow>) {
    rows.forEachIndexed { index, row ->
        addView((context as BaseTabActivity).buildPageCard(row))
        if (index < rows.lastIndex) addView((context as BaseTabActivity).buildDivider())
    }
}

internal fun BaseTabActivity.buildDivider(): View =
    View(this).apply {
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(1),
        ).apply {
            marginStart = dp(68)
            marginEnd = dp(16)
        }
        setBackgroundColor(getColor(R.color.border_color))
    }

internal fun BaseTabActivity.textView(
    value: String,
    size: Float,
    colorRes: Int,
    bold: Boolean = false,
): TextView = TextView(this).apply {
    text = value
    textSize = size
    setTextColor(getColor(colorRes))
    includeFontPadding = false
    if (bold) typeface = Typeface.DEFAULT_BOLD
}

internal fun BaseTabActivity.oval(color: Int): GradientDrawable =
    GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(color)
    }

internal fun BaseTabActivity.dp(value: Int): Int =
    (value * resources.displayMetrics.density).toInt()
