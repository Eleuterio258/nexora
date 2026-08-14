package tech.e258tech.paycore

import android.os.Bundle
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.AbrirSessaoRequest
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.ApiErrorParser
import tech.e258tech.paycore.utils.PermissaoHelper
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class AberturaCaixaActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_abertura_caixa)

        // Se já houver uma sessão de caixa activa (mesmo aberta offline, ainda sem
        // sessaoAtualId do servidor), não reabrir — volta ao ecrã que nos trouxe aqui
        // (Nova Venda/Pagamento), não ao Dashboard, para não perder o contexto da venda.
        if (PosStore.sessaoAtualLocalId != null) {
            finish()
            return
        }

        val etFundo = findViewById<EditText>(R.id.et_abertura_fundo)
        val btnAbrir = findViewById<MaterialButton>(R.id.btn_abrir_caixa)

        btnAbrir.setOnClickListener {
            val valorTexto = etFundo.text.toString().trim()
            val openingAmount = valorTexto.toDoubleOrNull() ?: 0.0

            if (SessionRepository.terminalId.isBlank()) {
                Toast.makeText(this, "Terminal não configurado", Toast.LENGTH_LONG).show()
                return@setOnClickListener
            }

            btnAbrir.isEnabled = false

            val terminalId = SessionRepository.terminalId.toLongOrNull()
            if (terminalId == null) {
                Toast.makeText(this, "ID do terminal inválido", Toast.LENGTH_LONG).show()
                btnAbrir.isEnabled = true
                return@setOnClickListener
            }

            lifecycleScope.launch {
                try {
                    val response = ApiClient.service.abrirSessao(
                        AbrirSessaoRequest(terminalId = terminalId, openingAmount = openingAmount)
                    )
                    val body = response.body()
                    if (response.isSuccessful && body != null) {
                        // Servidor confirmou já — grava a sessão sincronizada de imediato.
                        PosStore.registarAberturaCaixa(terminalId, openingAmount, serverId = body.id)
                        // Volta ao ecrã de origem (Nova Venda/Pagamento) em vez do Dashboard —
                        // quem chamou isto estava a meio de uma venda, não a começar do zero.
                        finish()
                        return@launch
                    }
                    val parsed = ApiErrorParser.parse(response)
                    // 403 genérico de permissão RBAC revogada (pos:operar_pos) — não confundir
                    // com o 403 "funcionário não autorizado NESTE terminal" (Fase 3 do plano de
                    // correcção), que é um erro operacional a mostrar directamente ao operador,
                    // não uma revogação de permissão a resincronizar.
                    if (response.code() == 403 && !ApiErrorParser.isFalhaAutorizacaoTerminal(parsed.rawMessage)) {
                        PermissaoHelper.aoReceber403(this@AberturaCaixaActivity)
                        return@launch
                    }
                    // Resposta real do servidor a rejeitar (ex.: terminal inactivo, já tem sessão
                    // aberta, sem armazém, não autorizado neste terminal) — não é falta de rede,
                    // continua bloqueado.
                    Toast.makeText(this@AberturaCaixaActivity, parsed.userMessage, Toast.LENGTH_LONG).show()
                    btnAbrir.isEnabled = true
                } catch (e: Exception) {
                    // Falha de rede (não resposta do servidor) — abre offline; o SyncWorker
                    // reconcilia com o servidor assim que houver ligação (ver PosStore.
                    // sincronizarSessoesCaixaPendentes).
                    PosStore.registarAberturaCaixa(terminalId, openingAmount, serverId = null)
                    Toast.makeText(
                        this@AberturaCaixaActivity,
                        "Sem ligação — caixa aberto offline, será sincronizado automaticamente.",
                        Toast.LENGTH_LONG
                    ).show()
                    finish()
                }
            }
        }
    }
}
