package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.text.InputType
import android.widget.ArrayAdapter
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import com.google.android.material.card.MaterialCardView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.MovimentoCaixaRequest
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.ApiErrorParser
import tech.e258tech.paycore.utils.PermissaoHelper
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class DashboardActivity : AppCompatActivity() {

    override fun onResume() {
        super.onResume()
        atualizarResumo()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_dashboard)

        // Cards do dashboard
        findViewById<MaterialCardView>(R.id.card_nova_venda).setOnClickListener {
            startActivity(Intent(this, NovaVendaActivity::class.java))
        }
        findViewById<MaterialCardView>(R.id.card_historico).setOnClickListener {
            startActivity(Intent(this, HistoricoActivity::class.java))
        }
        findViewById<MaterialCardView>(R.id.card_fecho_caixa).setOnClickListener {
            startActivity(Intent(this, FechoCaixaActivity::class.java))
        }
        findViewById<MaterialCardView>(R.id.card_suporte).setOnClickListener {
            startActivity(Intent(this, ConfiguracoesActivity::class.java))
        }
        findViewById<MaterialCardView>(R.id.card_movimento_caixa).setOnClickListener {
            abrirDialogMovimentoCaixa()
        }
    }

    private fun atualizarResumo() {
        val operador = SessionRepository.operadorAtual?.nome ?: "Sem sessao"
        val tenant   = SessionRepository.tenantNome.ifEmpty { "PayCore" }
        findViewById<TextView>(R.id.tv_dashboard_turno_vendas).text =
            "$tenant · ${PosStore.quantidadeVendasSessaoAtual()} vendas hoje"
        findViewById<TextView>(R.id.tv_dashboard_turno_terminal).text =
            "Operador: $operador · Total: ${PosStore.formatarValor(PosStore.totalVendasSessaoAtual())}"
    }

    // Suprimento (entrada)/sangria (saída)/depósito bancário/outro — só faz
    // sentido com a sessão já sincronizada com o servidor (o endpoint exige
    // um id de sessão do lado do servidor, ver pos/sessoes/{id}/movimentacoes).
    private fun abrirDialogMovimentoCaixa() {
        val sessionId = PosStore.sessaoAtualId
        if (sessionId == null) {
            Toast.makeText(this, "Sessão de caixa ainda não sincronizada com o servidor.", Toast.LENGTH_LONG).show()
            return
        }

        val tipos = arrayOf("suprimento", "sangria", "deposito", "outro")
        val rotulos = arrayOf("Suprimento (entrada)", "Sangria (saída)", "Depósito bancário", "Outro")

        val etValor = EditText(this).apply {
            hint = "Valor"
            inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
        }
        val etMotivo = EditText(this).apply { hint = "Motivo (opcional)" }
        val spinner = Spinner(this).apply {
            adapter = ArrayAdapter(this@DashboardActivity, android.R.layout.simple_spinner_dropdown_item, rotulos)
        }
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val pad = (16 * resources.displayMetrics.density).toInt()
            setPadding(pad, pad, pad, 0)
            addView(spinner)
            addView(etValor)
            addView(etMotivo)
        }

        AlertDialog.Builder(this)
            .setTitle("Movimento de Caixa")
            .setView(container)
            .setPositiveButton("Registar") { _, _ ->
                val valor = etValor.text.toString().toDoubleOrNull()
                if (valor == null || valor <= 0) {
                    Toast.makeText(this, "Introduza um valor válido", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                val tipo = tipos[spinner.selectedItemPosition]
                val motivo = etMotivo.text.toString().trim().ifBlank { null }
                lifecycleScope.launch {
                    val resultado = runCatching {
                        ApiClient.service.registarMovimentoCaixa(sessionId, MovimentoCaixaRequest(tipo, valor, motivo))
                    }
                    val resposta = resultado.getOrNull()
                    when {
                        resposta?.isSuccessful == true ->
                            Toast.makeText(this@DashboardActivity, "Movimento registado", Toast.LENGTH_SHORT).show()
                        resposta?.code() == 403 ->
                            PermissaoHelper.aoReceber403(this@DashboardActivity)
                        else -> {
                            val parsed = ApiErrorParser.parse(resposta)
                            Toast.makeText(this@DashboardActivity, parsed.userMessage, Toast.LENGTH_LONG).show()
                        }
                    }
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }
}

