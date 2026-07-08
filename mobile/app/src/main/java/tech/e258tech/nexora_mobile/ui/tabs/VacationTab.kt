package tech.e258tech.nexora_mobile.ui.tabs

import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.Toast
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.app
import tech.e258tech.nexora_mobile.data.model.PedidoFerias
import tech.e258tech.nexora_mobile.data.model.TipoAusencia
import tech.e258tech.nexora_mobile.ui.screens.main.MainActivity
import tech.e258tech.nexora_mobile.utils.Result

internal class VacationTab(private val activity: MainActivity) {

    fun show() {
        renderLoading()
        loadVacation()
    }

    private fun loadVacation() {
        activity.lifecycleScope.launch {
            val pedidos = activity.app.feriasRepository.listarPedidos()
            val tipos = activity.app.feriasRepository.listarTipos()

            if (pedidos is Result.Error) {
                renderMessage("Nao foi possivel carregar as ferias.")
                Toast.makeText(activity, pedidos.message, Toast.LENGTH_SHORT).show()
                return@launch
            }

            renderVacation(
                pedidos = (pedidos as? Result.Success)?.data.orEmpty(),
                tipos = (tipos as? Result.Success)?.data.orEmpty(),
            )

            if (tipos is Result.Error) {
                Toast.makeText(activity, tipos.message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun renderVacation(pedidos: List<PedidoFerias>, tipos: List<TipoAusencia>) =
        with(activity.binding.mainContent) {
            setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
            removeAllViews()
            addView(buildBanner(pedidos))
            addView(activity.buildPageTitle("Pedidos de Ferias", if (pedidos.isEmpty()) "Sem pedidos registados." else "Dados da API"))
            addRowsWithDividers(pedidos.take(10).map { it.toRow() })

            addView(activity.buildPageTitle("Tipos de ausencia", if (tipos.isEmpty()) "Sem tipos disponiveis." else "Tipos configurados"))
            addRowsWithDividers(tipos.take(5).map {
                PageRow(
                    title = it.nome,
                    subtitle = if (it.remunerada) "Remunerada" else "Nao remunerada",
                    value = it.diasAnuais?.let { dias -> formatNumber(dias) } ?: "--",
                )
            })

            addView(buildRequestButton())
        }

    private fun buildBanner(pedidos: List<PedidoFerias>): View {
        val pendentes = pedidos.count { it.estado.equals("pendente", ignoreCase = true) }
        val aprovados = pedidos.count { it.estado.equals("aprovado", ignoreCase = true) }
        val diasAprovados = pedidos.filter { it.estado.equals("aprovado", ignoreCase = true) }.sumOf { it.dias ?: 0 }

        return LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(activity.getColor(R.color.primary_blue))
            setPadding(activity.dp(20), activity.dp(20), activity.dp(20), activity.dp(28))
            addView(activity.textView("Ferias", 13f, R.color.white).apply { alpha = 0.8f })
            addView(activity.textView(diasAprovados.toString(), 52f, R.color.white, bold = true).apply {
                setPadding(0, activity.dp(6), 0, 0)
            })
            addView(activity.textView("$aprovados aprovados, $pendentes pendentes", 13f, R.color.white).apply {
                alpha = 0.75f
            })
        }
    }

    private fun PedidoFerias.toRow(): PageRow =
        PageRow(
            title = tipoNome ?: "Pedido #$id",
            subtitle = "$dataInicio - $dataFim${motivo?.let { " - $it" } ?: ""}",
            value = estado,
        )

    private fun buildRequestButton(): View =
        activity.textView("Novo pedido de ferias", 15f, R.color.white, bold = true).apply {
            gravity = Gravity.CENTER
            setPadding(activity.dp(16), activity.dp(14), activity.dp(16), activity.dp(14))
            background = GradientDrawable().apply {
                setColor(activity.getColor(R.color.primary_blue_dark))
                cornerRadius = activity.dp(12).toFloat()
            }
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { setMargins(activity.dp(16), activity.dp(12), activity.dp(16), activity.dp(8)) }
            setOnClickListener {
                Toast.makeText(activity, "Novo pedido de ferias", Toast.LENGTH_SHORT).show()
            }
        }

    private fun formatNumber(value: Double): String =
        if (value % 1.0 == 0.0) value.toInt().toString() else "%.1f".format(value)

    private fun renderLoading() = renderMessage("A carregar ferias...")

    private fun renderMessage(message: String) = with(activity.binding.mainContent) {
        setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
        removeAllViews()
        addView(activity.textView(message, 14f, R.color.text_secondary).apply {
            gravity = Gravity.CENTER
            setPadding(activity.dp(20), activity.dp(40), activity.dp(20), activity.dp(40))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
        })
    }
}
