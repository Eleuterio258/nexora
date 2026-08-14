package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.PinOperadorRequest
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.ApiErrorParser

/**
 * Ecrã de desbloqueio rápido, mostrado pelo SplashActivity quando já existe
 * uma sessão de funcionário em cache (evita obrigar email+password sempre
 * que a app é reaberta, mas também não deixa entrar sem confirmar "és
 * mesmo tu" — qualquer pessoa com o aparelho desbloqueado não devia entrar
 * directo no POS). Dois caminhos, um dos quais sempre real:
 *
 * - Biometria: BiometricPrompt do próprio Android, contra a impressão
 *   digital/face já inscrita no aparelho. Não faz pedido ao servidor — só
 *   confirma a identidade física de quem já tem a sessão em cache
 *   (SessionRepository.autenticarComBiometria), tal como um desbloqueio de app
 *   bancária.
 * - PIN: valida a sério contra o backend (POST /api/pos/login-operador —
 *   ver LoginOperadorPorPIN), que resolve o operador pelo PIN dentro do
 *   tenant de quem chama e devolve uma sessão de funcionário nova. Antes
 *   disto existir, o PIN comparava com um valor fixo "1234" no código —
 *   nunca teve correspondência real nenhuma.
 */
class PinLoginActivity : AppCompatActivity() {

    private val pin = StringBuilder()
    private val PIN_LENGTH = 4

    private lateinit var dots: List<ImageView>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_pin_login)

        dots = listOf(
            findViewById(R.id.pin_dot_1),
            findViewById(R.id.pin_dot_2),
            findViewById(R.id.pin_dot_3),
            findViewById(R.id.pin_dot_4)
        )

        val teclas = mapOf(
            R.id.key_0 to "0", R.id.key_1 to "1", R.id.key_2 to "2",
            R.id.key_3 to "3", R.id.key_4 to "4", R.id.key_5 to "5",
            R.id.key_6 to "6", R.id.key_7 to "7", R.id.key_8 to "8",
            R.id.key_9 to "9"
        )

        teclas.forEach { (id, digito) ->
            findViewById<FrameLayout>(id).setOnClickListener { adicionarDigito(digito) }
        }

        findViewById<FrameLayout>(R.id.key_apagar).setOnClickListener { apagar() }

        val botaoBiometria = findViewById<FrameLayout>(R.id.key_biometria)
        if (biometriaDisponivel()) {
            botaoBiometria.setOnClickListener { autenticarComBiometria() }
        } else {
            // Sem hardware/inscrição biométrica no aparelho — não finge que
            // funciona, desactiva o botão em vez de falhar ao tocar nele.
            botaoBiometria.isEnabled = false
            botaoBiometria.alpha = 0.35f
        }

        findViewById<MaterialButton>(R.id.btn_pin_login).setOnClickListener { validarPin() }

        findViewById<TextView>(R.id.tv_pin_terminar_sessao).setOnClickListener {
            PosStore.logoutFuncionario()
            startActivity(Intent(this, LoginActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            })
            finish()
        }

        // Tenta biometria automaticamente ao abrir o ecrã — poupa um toque a
        // quem já a tem inscrita; quem preferir PIN só tem de tocar num dígito.
        if (biometriaDisponivel()) autenticarComBiometria()
    }

    private fun biometriaDisponivel(): Boolean {
        val gestor = BiometricManager.from(this)
        return gestor.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.BIOMETRIC_WEAK
        ) == BiometricManager.BIOMETRIC_SUCCESS
    }

    private fun autenticarComBiometria() {
        val executor = ContextCompat.getMainExecutor(this)
        val prompt = BiometricPrompt(this, executor, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                if (SessionRepository.autenticarComBiometria()) {
                    abrirDashboard()
                } else {
                    Toast.makeText(this@PinLoginActivity, "Sessão expirada. Inicie sessão novamente.", Toast.LENGTH_LONG).show()
                    abrirLoginCompleto()
                }
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                // ERROR_USER_CANCELED / ERROR_NEGATIVE_BUTTON: o utilizador optou
                // por usar o PIN — não é um erro a mostrar, fica só no teclado.
                if (errorCode != BiometricPrompt.ERROR_USER_CANCELED &&
                    errorCode != BiometricPrompt.ERROR_NEGATIVE_BUTTON &&
                    errorCode != BiometricPrompt.ERROR_CANCELED
                ) {
                    Toast.makeText(this@PinLoginActivity, errString, Toast.LENGTH_SHORT).show()
                }
            }
        })

        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Desbloquear PayCore")
            .setSubtitle("Confirme a sua identidade para continuar")
            .setNegativeButtonText("Usar PIN")
            .build()
        prompt.authenticate(info)
    }

    private fun adicionarDigito(digito: String) {
        if (pin.length >= PIN_LENGTH) return
        pin.append(digito)
        atualizarDots()
        if (pin.length == PIN_LENGTH) validarPin()
    }

    private fun apagar() {
        if (pin.isEmpty()) return
        pin.deleteCharAt(pin.length - 1)
        atualizarDots()
    }

    private fun atualizarDots() {
        dots.forEachIndexed { index, dot ->
            dot.setImageResource(
                if (index < pin.length) R.drawable.pin_dot_preenchido
                else R.drawable.pin_dot_vazio
            )
        }
    }

    private fun validarPin() {
        if (pin.length < PIN_LENGTH) {
            Toast.makeText(this, "Introduza os 4 dígitos", Toast.LENGTH_SHORT).show()
            return
        }
        val codigo = pin.toString()
        lifecycleScope.launch {
            val resultado = runCatching { ApiClient.service.loginOperadorPorPin(PinOperadorRequest(codigo)) }
            val resposta = resultado.getOrNull()
            val corpo = resposta?.body()
            if (resposta?.isSuccessful == true && corpo?.accessToken != null) {
                ApiClient.saveEmployeeTokens(corpo)
                val user = corpo.user ?: corpo.partialUser
                if (user != null) {
                    val acessoResponse = runCatching { ApiClient.service.meAcesso() }.getOrNull()
                    val modulos = acessoResponse?.body()?.modulos ?: emptyMap()
                    SessionRepository.sincronizarSessaoApi(
                        user = user,
                        tenantIdApi = corpo.tenant?.id?.toString() ?: "",
                        modulos = modulos
                    )
                }
                abrirDashboard()
            } else {
                val parsed = ApiErrorParser.parse(resposta)
                Toast.makeText(this@PinLoginActivity, parsed.userMessage, Toast.LENGTH_LONG).show()
                pin.clear()
                atualizarDots()
            }
        }
    }

    private fun abrirDashboard() {
        startActivity(Intent(this, DashboardActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        })
        finish()
    }

    private fun abrirLoginCompleto() {
        startActivity(Intent(this, LoginActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        })
        finish()
    }
}
