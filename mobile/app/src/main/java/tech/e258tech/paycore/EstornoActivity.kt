package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.api.PinOperadorRequest
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class EstornoActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_estorno)

        val etPinSupervisor = findViewById<EditText>(R.id.et_pin_supervisor)
        findViewById<MaterialButton>(R.id.btn_confirmar_estorno).setOnClickListener {
            // Estornar é uma acção sensível (reverte dinheiro já cobrado) — não confiar em
            // permissões em cache há tempo de mais sem confirmar junto do ERP.
            if (SessionRepository.permissoesEstaoDesactualizadas()) {
                Toast.makeText(
                    this,
                    "Permissões desactualizadas há mais de 24h — liga-te à rede para continuar.",
                    Toast.LENGTH_LONG
                ).show()
                return@setOnClickListener
            }

            val pin = etPinSupervisor.text.toString().trim()
            if (pin.isEmpty()) {
                etPinSupervisor.error = "Introduza o PIN do supervisor"
                return@setOnClickListener
            }

            lifecycleScope.launch {
                try {
                    val response = ApiClient.service.loginOperadorPorPin(PinOperadorRequest(pin))
                    val body = response.body()
                    // O backend passou a devolver as permissões do operador no próprio
                    // envelope de login (campo "modulos"). Em vez de confiar no nome do
                    // cargo, verificamos a permissão fina pos:supervisionar_pos.
                    val podeSupervisionar = body?.modulos?.get(Permissoes.MODULO_POS)
                        ?.any { it.equals(Permissoes.SUPERVISIONAR_POS, ignoreCase = true) } == true

                    if (response.isSuccessful && podeSupervisionar) {
                        val transacao = PosStore.estornarTransacaoSelecionada()
                        if (transacao != null) {
                            startActivity(
                                Intent(this@EstornoActivity, ComprovativoActivity::class.java)
                                    .putExtra("transacao_id", transacao.id)
                            )
                            finish()
                        }
                    } else {
                        Toast.makeText(
                            this@EstornoActivity,
                            "PIN de supervisor inválido ou sem permissão de supervisão.",
                            Toast.LENGTH_LONG
                        ).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(
                        this@EstornoActivity,
                        "Erro de ligação. Verifique a internet e tente novamente.",
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
    }
}
