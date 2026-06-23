package tech.e258tech.nexora_mobile.ui.tabs

import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.Toast
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.app
import tech.e258tech.nexora_mobile.data.model.HomeResponse
import tech.e258tech.nexora_mobile.ui.screens.main.MainActivity
import tech.e258tech.nexora_mobile.utils.Result

internal class HomeTab(private val activity: MainActivity) {

    private var cachedHome: HomeResponse? = null

    fun setupDashboard() {
        activity.lifecycleScope.launch {
            activity.binding.tvUserName.text = activity.app.tokenManager.getUserNome().ifBlank { "Utilizador" }
        }
    }

    fun show() {
        renderLoading()
        cachedHome?.let { renderHome(it) }
        loadHome()
    }

    private fun loadHome() {
        activity.lifecycleScope.launch {
            when (val result = activity.app.homeRepository.getHome()) {
                is Result.Success -> {
                    cachedHome = result.data
                    renderHome(result.data)
                }
                is Result.Error -> {
                    renderMessage("Nao foi possivel carregar a Home.")
                    Toast.makeText(activity, result.message, Toast.LENGTH_SHORT).show()
                }
                Result.Loading -> Unit
            }
        }
    }

    private fun renderLoading() = with(activity.binding.mainContent) {
        setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
        removeAllViews()
        addView(activity.textView("A carregar Home...", 14f, R.color.text_secondary).apply {
            gravity = Gravity.CENTER
            setPadding(activity.dp(20), activity.dp(40), activity.dp(20), activity.dp(40))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
        })
    }

    private fun renderHome(home: HomeResponse) = with(activity.binding.mainContent) {
        setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
        removeAllViews()

        addView(activity.buildPageTitle("Inicio", "Resumo actualizado da API."))
        addView(buildSummaryGrid(home))

        addSection(
            title = "Notificacoes",
            emptyText = "Sem notificacoes pendentes.",
            rows = home.notificacoes.take(3).map {
                PageRow(it.titulo, it.corpo ?: it.tipo, formatTime(it.criadoEm))
            },
        )

        addSection(
            title = "Comunicados",
            emptyText = "Sem comunicados recentes.",
            rows = home.comunicados.take(3).map {
                PageRow(it.titulo, if (it.lido) "Lido" else "Novo", formatTime(it.criadoEm))
            },
        )

        addSection(
            title = "Aniversarios",
            emptyText = "Sem aniversarios proximos.",
            rows = home.aniversarios.take(3).map {
                PageRow(it.nome, "Aniversario", "%02d/%02d".format(it.dia, it.mes))
            },
        )
    }

    private fun buildSummaryGrid(home: HomeResponse): View {
        val items = listOf(
            SummaryItem("Ferias", formatNumber(home.saldoFerias.diasDisponiveis), "dias disponiveis"),
            SummaryItem("Dias", home.assiduidadeMes.diasTrabalhados.toString(), "trabalhados"),
            SummaryItem("Horas", formatNumber(home.assiduidadeMes.horasTotais), "este mes"),
            SummaryItem("Pedidos", home.pedidosPendentes.toString(), "pendentes"),
        )

        return GridLayout(activity).apply {
            columnCount = 2
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                setMargins(activity.dp(12), activity.dp(4), activity.dp(12), activity.dp(10))
            }

            items.forEach { item ->
                addView(summaryCard(item).apply {
                    layoutParams = GridLayout.LayoutParams(
                        GridLayout.spec(GridLayout.UNDEFINED, 1f),
                        GridLayout.spec(GridLayout.UNDEFINED, 1f),
                    ).apply {
                        width = 0
                        height = ViewGroup.LayoutParams.WRAP_CONTENT
                        setMargins(activity.dp(4), activity.dp(4), activity.dp(4), activity.dp(8))
                    }
                })
            }
        }
    }

    private fun summaryCard(item: SummaryItem): View =
        LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = activity.dp(96)
            setPadding(activity.dp(14), activity.dp(12), activity.dp(14), activity.dp(12))
            background = GradientDrawable().apply {
                setColor(activity.getColor(R.color.white))
                cornerRadius = activity.dp(8).toFloat()
                setStroke(activity.dp(1), activity.getColor(R.color.border_color))
            }
            addView(activity.textView(item.label, 12f, R.color.text_secondary))
            addView(activity.textView(item.value, 24f, R.color.text_primary, bold = true).apply {
                setPadding(0, activity.dp(6), 0, 0)
            })
            addView(activity.textView(item.subtitle, 11f, R.color.text_hint).apply {
                setPadding(0, activity.dp(4), 0, 0)
            })
        }

    private fun LinearLayout.addSection(title: String, emptyText: String, rows: List<PageRow>) {
        addView(activity.buildPageTitle(title, if (rows.isEmpty()) emptyText else "Dados da API"))
        rows.forEach { addView(activity.buildPageCard(it)) }
    }

    private fun renderMessage(message: String) = with(activity.binding.mainContent) {
        setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
        removeAllViews()
        addView(activity.textView(message, 14f, R.color.text_secondary).apply {
            gravity = Gravity.CENTER
            setPadding(activity.dp(20), activity.dp(40), activity.dp(20), activity.dp(40))
        })
    }

    private fun formatNumber(value: Double): String =
        if (value % 1.0 == 0.0) value.toInt().toString() else "%.1f".format(value)

    private fun formatTime(value: String): String {
        val timeStart = value.indexOf('T')
        return if (timeStart >= 0 && value.length >= timeStart + 6) {
            value.substring(timeStart + 1, timeStart + 6)
        } else {
            value.take(10)
        }
    }

    private data class SummaryItem(
        val label: String,
        val value: String,
        val subtitle: String,
    )
}
