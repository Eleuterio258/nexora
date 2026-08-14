package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.setPadding
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.FecharSessaoRequest
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.utils.PermissaoHelper
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class FechoCaixaActivity : AppCompatActivity() {

    private val contagemNotasFields = mutableMapOf<String, EditText>()

    override fun onResume() {
        super.onResume()
        atualizarTotais()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_fecho_caixa)

        findViewById<android.widget.ImageButton>(R.id.btn_voltar).setOnClickListener { finish() }

        val etContagem = findViewById<EditText>(R.id.et_fecho_contagem)
        val etJustificativa = findViewById<EditText>(R.id.et_fecho_justificativa)
        val tvResultado = findViewById<TextView>(R.id.tv_fecho_resultado)
        val btnFechar = findViewById<MaterialButton>(R.id.btn_fechar_turno)

        criarCamposContagemNotas()

        btnFechar.setOnClickListener {
            // sessaoAtualLocalId (não sessaoAtualId) — gate independente de já ter
            // sincronizado com o servidor.
            if (PosStore.sessaoAtualLocalId == null) {
                Toast.makeText(this, "Nenhuma sessão de caixa activa", Toast.LENGTH_LONG).show()
                return@setOnClickListener
            }

            val valorTexto = etContagem.text.toString().trim()
            val closingAmount = valorTexto.toDoubleOrNull()
            if (closingAmount == null) {
                Toast.makeText(this, "Introduza o valor contado", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val justificativa = etJustificativa.text.toString().trim().ifBlank { null }
            val contagemNotas = lerContagemNotas()

            btnFechar.isEnabled = false
            val sessionId = PosStore.sessaoAtualId

            lifecycleScope.launch {
                // Só tenta o servidor se a abertura já sincronizou (sessionId != null) — sem
                // isso o fecho é sempre local (não há id de sessão do lado do servidor ainda).
                if (sessionId != null) {
                    try {
                        val response = ApiClient.service.fecharSessao(
                            sessionId,
                            FecharSessaoRequest(
                                closingAmount = closingAmount,
                                justificativa = justificativa,
                                contagemNotas = contagemNotas
                            )
                        )
                        if (response.code() == 403) {
                            PermissaoHelper.aoReceber403(this@FechoCaixaActivity)
                            return@launch
                        }
                        val body = response.body()
                        if (response.isSuccessful && body != null) {
                            PosStore.registarFechoCaixa(closingAmount, diferencaOficial = body.diferenca, justificativa = justificativa)
                            mostrarResultado(tvResultado, body.valorEsperado, body.diferenca, estimado = false, detalhamentoMetodos = body.detalhamentoMetodos)
                            btnFechar.postDelayed({ abrirDashboard() }, 2000)
                            return@launch
                        }
                        // 422 tipicamente significa "há diferença, falta justificativa" — chama a
                        // atenção para o campo em vez de só mostrar a mensagem de erro.
                        if (response.code() == 422 && justificativa == null) {
                            etJustificativa.error = "Indique o motivo da diferença de caixa"
                            etJustificativa.requestFocus()
                        }
                        val msg = response.errorBody()?.string()?.takeIf { it.isNotBlank() }
                            ?: "Não foi possível fechar o caixa"
                        Toast.makeText(this@FechoCaixaActivity, msg, Toast.LENGTH_LONG).show()
                        btnFechar.isEnabled = true
                        return@launch
                    } catch (e: Exception) {
                        // Falha de rede — cai para o fecho local abaixo.
                    }
                }

                // Sem sessão sincronizada ou sem ligação: calcula localmente. O SyncWorker
                // substitui a diferença estimada pela oficial assim que sincronizar (ver
                // PosStore.sincronizarSessoesCaixaPendentes) — a justificativa viaja junto
                // para esse retry não poder ficar preso por falta dela.
                val sessao = PosStore.registarFechoCaixa(closingAmount, justificativa = justificativa)
                if (sessao == null) {
                    Toast.makeText(this@FechoCaixaActivity, "Não foi possível fechar o caixa", Toast.LENGTH_LONG).show()
                    btnFechar.isEnabled = true
                    return@launch
                }
                val diferenca = sessao.diferencaLocal ?: 0.0
                mostrarResultado(tvResultado, valorEsperado = closingAmount - diferenca, diferenca = diferenca, estimado = true)
                Toast.makeText(
                    this@FechoCaixaActivity,
                    "Sem ligação — fecho registado offline, valores estimados até sincronizar.",
                    Toast.LENGTH_LONG
                ).show()
                btnFechar.postDelayed({ abrirDashboard() }, 2000)
            }
        }
    }

    private fun criarCamposContagemNotas() {
        val container = findViewById<LinearLayout>(R.id.layout_contagem_notas)
        val denominacoes = listOf("1000", "500", "200", "100", "50", "20", "10", "5")
        val layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(0, 8, 0, 0) }

        denominacoes.forEach { valor ->
            val editText = EditText(this).apply {
                this.layoutParams = layoutParams
                background = getDrawable(R.drawable.bg_input_login)
                hint = "Quantidade de $valor MT"
                inputType = android.text.InputType.TYPE_CLASS_NUMBER
                setPadding(48, 0, 48, 0)
                minHeight = 104
                gravity = android.view.Gravity.CENTER_VERTICAL
            }
            container.addView(editText)
            contagemNotasFields[valor] = editText
        }
    }

    private fun lerContagemNotas(): Map<String, Int>? {
        val map = mutableMapOf<String, Int>()
        contagemNotasFields.forEach { (valor, editText) ->
            val quantidade = editText.text.toString().trim().toIntOrNull()
            if (quantidade != null && quantidade > 0) {
                map[valor] = quantidade
            }
        }
        return map.takeIf { it.isNotEmpty() }
    }

    // Rótulos para o enum real do backend (ver pos.CriarVenda / pos.FecharSessao):
    // numerario|transferencia|tpa|mpesa|emola|outro.
    private val rotuloMetodoErp = mapOf(
        "numerario" to "Numerário",
        "transferencia" to "Transferência",
        "tpa" to "TPA (Cartão/Contactless)",
        "mpesa" to "M-Pesa",
        "emola" to "E-Mola",
        "outro" to "Outro"
    )

    private fun mostrarResultado(
        tvResultado: TextView,
        valorEsperado: Double,
        diferenca: Double,
        estimado: Boolean,
        detalhamentoMetodos: Map<String, Double>? = null
    ) {
        val diferencaTexto = when {
            diferenca > 0 -> "Sobram ${PosStore.formatarValor(diferenca)}"
            diferenca < 0 -> "Faltam ${PosStore.formatarValor(kotlin.math.abs(diferenca))}"
            else -> "Sem diferença"
        }
        tvResultado.text = buildString {
            appendLine(if (estimado) "Fecho registado offline" else "Fecho registado com sucesso")
            appendLine("Valor esperado: ${PosStore.formatarValor(valorEsperado)}${if (estimado) " (estimado)" else ""}")
            appendLine("Diferença: $diferencaTexto${if (estimado) " (estimado)" else ""}")
            if (estimado) {
                appendLine("Confirmado após sincronizar com o servidor.")
            } else if (!detalhamentoMetodos.isNullOrEmpty()) {
                appendLine()
                appendLine("Detalhamento por método (ERP):")
                detalhamentoMetodos.forEach { (metodo, valor) ->
                    val rotulo = rotuloMetodoErp[metodo] ?: metodo.replaceFirstChar { it.uppercase() }
                    appendLine("$rotulo: ${PosStore.formatarValor(valor)}")
                }
            }
        }
        tvResultado.visibility = View.VISIBLE
    }

    private fun atualizarTotais() {
        val totais = PosStore.totaisPorMetodoSessaoAtual()
        val texto = buildString {
            appendLine("Cartao: ${PosStore.formatarValor(totais["Cartao"] ?: 0.0)}")
            appendLine("NFC / Contactless: ${PosStore.formatarValor(totais["NFC / Contactless"] ?: 0.0)}")
            appendLine("QR Code: ${PosStore.formatarValor(totais["QR Code"] ?: 0.0)}")
            appendLine("Dinheiro: ${PosStore.formatarValor(totais["Dinheiro"] ?: 0.0)}")
            append("Total Geral: ${PosStore.formatarValor(PosStore.totalVendasSessaoAtual())}")
        }
        findViewById<TextView>(R.id.tv_fecho_totais).text = texto
    }

    private fun abrirDashboard() {
        startActivity(Intent(this, DashboardActivity::class.java))
        finish()
    }
}
