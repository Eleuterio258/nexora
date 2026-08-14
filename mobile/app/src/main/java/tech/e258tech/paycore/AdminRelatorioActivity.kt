package tech.e258tech.paycore

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper

class AdminRelatorioActivity : AppCompatActivity() {

    override fun onResume() {
        super.onResume()
        atualizarResumo()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val podeEntrar = SessionRepository.temPermissao(Permissoes.MODULO_POS, Permissoes.OPERAR_POS) ||
                         SessionRepository.temPermissaoAdmin()
        if (!podeEntrar) {
            PermissaoHelper.mostrarSemPermissaoEFechar(this)
            return
        }
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_relatorio)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<MaterialButton>(R.id.btn_admin_relatorio_voltar).setOnClickListener { finish() }
    }

    private fun atualizarResumo() {
        val resumoView = findViewById<TextView>(R.id.tv_admin_relatorio_resumo)
        resumoView.text = "A carregar relatórios..."

        lifecycleScope.launch {
            val relatorio = buildString {
                appendLine("Período: últimos 30 dias")
                appendLine()

                // Vendas por dia
                AdminApiRepository.loadRelatorioVendas(agruparPor = "dia")
                    .onSuccess { resp ->
                        appendLine("═══ VENDAS POR DIA ═══")
                        if (resp.data.isEmpty()) {
                            appendLine("Nenhuma venda no período.")
                        } else {
                            val totalGeral = resp.data.sumOf { it.totalValor }
                            resp.data.forEach { row ->
                                appendLine("${row.rotulo}: ${PosStore.formatarValor(row.totalValor)} (${row.totalVendas} vendas)")
                            }
                            appendLine("Total: ${PosStore.formatarValor(totalGeral)}")
                        }
                    }
                    .onFailure { appendLine("Vendas: erro ao carregar") }
                appendLine()

                // Top produtos
                AdminApiRepository.loadRelatorioTopProdutos(limit = 5)
                    .onSuccess { resp ->
                        appendLine("═══ TOP PRODUTOS ═══")
                        if (resp.data.isEmpty()) {
                            appendLine("Nenhum produto vendido no período.")
                        } else {
                            resp.data.forEach { row ->
                                appendLine("${row.nome}: ${row.quantidadeTotal.toInt()} un. - ${PosStore.formatarValor(row.valorTotal)}")
                            }
                        }
                    }
                    .onFailure { appendLine("Top produtos: erro ao carregar") }
                appendLine()

                // Cancelamentos
                AdminApiRepository.loadRelatorioCancelamentos()
                    .onSuccess { resp ->
                        appendLine("═══ CANCELAMENTOS ═══")
                        if (resp.data.isEmpty()) {
                            appendLine("Nenhum cancelamento no período.")
                        } else {
                            appendLine("Total: ${resp.data.size} cancelamento(s)")
                            resp.data.take(3).forEach { row ->
                                appendLine("#${row.numero}: ${PosStore.formatarValor(row.total)}${row.motivoCancelamento?.let { " - $it" } ?: ""}")
                            }
                        }
                    }
                    .onFailure { appendLine("Cancelamentos: erro ao carregar") }
                appendLine()

                // Fechos de caixa
                AdminApiRepository.loadRelatorioFechoCaixa()
                    .onSuccess { resp ->
                        appendLine("═══ FECHOS DE CAIXA ═══")
                        if (resp.data.isEmpty()) {
                            appendLine("Nenhum fecho no período.")
                        } else {
                            resp.data.take(5).forEach { row ->
                                val diferencaTexto = row.diferenca?.let {
                                    when {
                                        it > 0 -> "+${PosStore.formatarValor(it)}"
                                        it < 0 -> PosStore.formatarValor(it)
                                        else -> "0,00 MT"
                                    }
                                } ?: "—"
                                appendLine("${row.terminalNome}: ${PosStore.formatarValor(row.closingAmount ?: 0.0)} (dif. $diferencaTexto)")
                            }
                        }
                    }
                    .onFailure { appendLine("Fechos: erro ao carregar") }
                appendLine()

                // Terminais
                AdminApiRepository.loadRelatorioTerminais()
                    .onSuccess { terminais ->
                        appendLine("═══ TERMINAIS ═══")
                        val ativos = terminais.count { it.activo }
                        appendLine("Ativos: $ativos / Total: ${terminais.size}")
                        terminais.forEach { t ->
                            val status = if (t.activo) "ATIVO" else "INATIVO"
                            appendLine("${t.nome} ($status)")
                        }
                    }
                    .onFailure { appendLine("Terminais: erro ao carregar") }
            }

            resumoView.text = relatorio
        }
    }
}
