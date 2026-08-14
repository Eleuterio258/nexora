package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.AuthLoginRequest
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.ApiErrorParser

class LoginActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)

        val tilOperador = findViewById<TextInputLayout>(R.id.til_operador)
        val tilSenha    = findViewById<TextInputLayout>(R.id.til_senha)
        val etOperador  = findViewById<TextInputEditText>(R.id.et_operador)
        val etSenha     = findViewById<TextInputEditText>(R.id.et_senha)
        val tvErro      = findViewById<TextView>(R.id.tv_erro)
        val btnLogin    = findViewById<MaterialButton>(R.id.btn_login)

        // Se já existe sessão de funcionário válida, saltar para seleção
        if (ApiClient.isLoggedIn && SessionRepository.operadorAtual != null) {
            abrirDashboard()
            return
        }

        btnLogin.setOnClickListener {
            val email = etOperador.text.toString().trim()
            val senha = etSenha.text.toString()

            tilOperador.error = null
            tilSenha.error    = null
            tvErro.visibility = View.GONE

            when {
                email.isEmpty() -> { tilOperador.error = "Introduza o email"; return@setOnClickListener }
                senha.isEmpty() -> { tilSenha.error    = "Introduza a senha"; return@setOnClickListener }
            }

            btnLogin.isEnabled = false

            lifecycleScope.launch {
                try {
                    val response = ApiClient.service.authLogin(
                        AuthLoginRequest(email = email, password = senha)
                    )
                    val body = response.body()

                    if (response.isSuccessful && body?.accessToken != null) {
                        if (body.twoFactorRequired) {
                            tvErro.text = "Autenticação de dois fatores necessária."
                            tvErro.visibility = View.VISIBLE
                            return@launch
                        }

                        ApiClient.saveEmployeeTokens(body)
                        val user = body.user
                            ?: body.partialUser
                            ?: throw IllegalStateException("Resposta sem dados do utilizador")
                        val tenant = body.tenant

                        // Carregar dados e permissões do ERP
                        val meResponse = runCatching { ApiClient.service.me() }.getOrNull()
                        val meBody = meResponse?.body()
                        val userCompleto = meBody ?: user

                        val acessoResponse = runCatching { ApiClient.service.meAcesso() }.getOrNull()
                        val modulos = acessoResponse?.body()?.modulos ?: emptyMap()

                        SessionRepository.sincronizarSessaoApi(
                            user = userCompleto,
                            tenantIdApi = tenant?.id?.toString() ?: "",
                            modulos = modulos
                        )

                        abrirDashboard()
                    } else {
                        val parsed = ApiErrorParser.parse(response)
                        tvErro.text = parsed.userMessage
                        tvErro.visibility = View.VISIBLE
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    tvErro.text = getString(R.string.login_erro_generico)
                    tvErro.visibility = View.VISIBLE
                } finally {
                    btnLogin.isEnabled = true
                }
            }
        }

        findViewById<TextView>(R.id.tv_esqueci_senha).setOnClickListener {
            startActivity(Intent(this, RecuperarSenhaActivity::class.java))
        }
    }

    private fun abrirDashboard() {
        startActivity(
            Intent(this, DashboardActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
        )
        finish()
    }
}
