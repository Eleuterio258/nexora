package tech.e258tech.nexora_mobile.ui.tabs

import android.view.Gravity
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.Toast
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.app
import tech.e258tech.nexora_mobile.data.model.Justificacao
import tech.e258tech.nexora_mobile.data.model.RegistoPresenca
import tech.e258tech.nexora_mobile.data.model.ResumoAssiduidadeResponse
import tech.e258tech.nexora_mobile.ui.screens.main.MainActivity
import tech.e258tech.nexora_mobile.utils.Result

internal class AttendanceTab(private val activity: MainActivity) {

    fun show() {
        renderLoading()
        loadAttendance()
    }

    private fun loadAttendance() {
        activity.lifecycleScope.launch {
            val resumo = activity.app.assiduidadeRepository.getResumo()
            val registos = activity.app.assiduidadeRepository.listarRegistos()
            val justificacoes = activity.app.assiduidadeRepository.listarJustificacoes()

            if (resumo is Result.Error) {
                renderMessage("Nao foi possivel carregar a assiduidade.")
                Toast.makeText(activity, resumo.message, Toast.LENGTH_SHORT).show()
                return@launch
            }

            renderAttendance(
                resumo = (resumo as? Result.Success)?.data,
                registos = (registos as? Result.Success)?.data.orEmpty(),
                justificacoes = (justificacoes as? Result.Success)?.data.orEmpty(),
            )

            listOf(registos, justificacoes).filterIsInstance<Result.Error>().firstOrNull()?.let {
                Toast.makeText(activity, it.message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun renderAttendance(
        resumo: ResumoAssiduidadeResponse?,
        registos: List<RegistoPresenca>,
        justificacoes: List<Justificacao>,
    ) = with(activity.binding.mainContent) {
        setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
        removeAllViews()
        addView(activity.buildPageTitle("Assiduidade", "Registos de presenca, atrasos e horas trabalhadas."))

        val rows = mutableListOf<PageRow>()
        resumo?.let {
            rows += PageRow("Dias trabalhados", "${it.mes}/${it.ano}", it.diasTrabalhados.toString())
            rows += PageRow("Horas totais", "Este mes", formatNumber(it.horasTotais))
            rows += PageRow("Atrasos", "Registos do periodo", it.atrasos.toString())
            rows += PageRow("Faltas", "Registos do periodo", it.faltas.toString())
            rows += PageRow("Horas extra", "Este mes", it.horasExtra.toString())
        }
        addRowsWithDividers(rows)

        addView(activity.buildPageTitle("Registos recentes", if (registos.isEmpty()) "Sem registos." else "Ultimos registos da API"))
        addRowsWithDividers(registos.take(8).map {
            PageRow(
                title = it.data,
                subtitle = "${it.tipo}${formatHours(it)}",
                value = listOfNotNull(it.horaEntrada, it.horaSaida).joinToString(" - ").ifBlank { "--" },
            )
        })

        addView(activity.buildPageTitle("Justificacoes", if (justificacoes.isEmpty()) "Sem justificacoes." else "Pedidos submetidos"))
        addRowsWithDividers(justificacoes.take(5).map {
            PageRow(
                title = it.tipo.replaceFirstChar { c -> c.uppercaseChar() }.toString(),
                subtitle = "${it.data} - ${it.motivo}",
                value = it.estado,
            )
        })
    }

    private fun formatHours(registo: RegistoPresenca): String =
        registo.horasTrabalhadas?.let { " - ${formatNumber(it)}h" } ?: ""

    private fun formatNumber(value: Double): String =
        if (value % 1.0 == 0.0) value.toInt().toString() else "%.1f".format(value)

    private fun renderLoading() = renderMessage("A carregar assiduidade...")

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
