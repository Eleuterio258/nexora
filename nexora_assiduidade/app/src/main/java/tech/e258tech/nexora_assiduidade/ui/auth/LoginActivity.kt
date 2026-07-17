package tech.e258tech.nexora_assiduidade.ui.auth

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ErpLoginRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.main.MainActivity
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.RoleUtils
import tech.e258tech.nexora_assiduidade.work.SyncAttendanceWorker
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_FUNCIONARIO_EMAIL
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_FUNCIONARIO_PASSWORD
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_GESTOR_EMAIL
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_GESTOR_PASSWORD
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_ADMIN_EMAIL
import tech.e258tech.nexora_assiduidade.utils.Constants.DEMO_ADMIN_PASSWORD
import tech.e258tech.nexora_assiduidade.utils.SessionManager

class LoginActivity : AppCompatActivity() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager

    private lateinit var etEmail: EditText
    private lateinit var etPassword: EditText
    private lateinit var btnLogin: Button
    private lateinit var btnDemoFuncionario: View
    private lateinit var btnDemoGestor: View
    private lateinit var btnDemoAdmin: View
    private lateinit var progressBar: ProgressBar

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sessionManager = SessionManager(this)
        sessionManager.getOrCreateDeviceId()

        if (sessionManager.isLoggedIn()) {
            navigateToMain()
            return
        }

        setContentView(R.layout.auth_activity_login)

        initViews()
        setupListeners()
    }

    override fun onDestroy() {
        uiScope.cancel()
        super.onDestroy()
    }

    private fun initViews() {
        etEmail = findViewById(R.id.etEmail)
        etPassword = findViewById(R.id.etPassword)
        btnLogin = findViewById(R.id.btnLogin)
        btnDemoFuncionario = findViewById(R.id.btnDemoFuncionario)
        btnDemoGestor = findViewById(R.id.btnDemoGestor)
        btnDemoAdmin = findViewById(R.id.btnDemoAdmin)
        progressBar = findViewById(R.id.progressBar)
    }

    private fun setupListeners() {
        btnLogin.setOnClickListener {
            val username = etEmail.text.toString().trim()
            val password = etPassword.text.toString().trim()

            if (username.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "Preencha todos os campos", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            performLogin(username, password)
        }

        // Botões de atalho com credenciais fixas — só em builds de debug,
        // nunca em release (ver plano "alinhar login ao backend").
        if (!BuildConfig.DEBUG) {
            btnDemoFuncionario.visibility = View.GONE
            btnDemoGestor.visibility = View.GONE
            btnDemoAdmin.visibility = View.GONE
            return
        }

        btnDemoFuncionario.setOnClickListener {
            etEmail.setText(DEMO_FUNCIONARIO_EMAIL)
            etPassword.setText(DEMO_FUNCIONARIO_PASSWORD)
        }

        btnDemoGestor.setOnClickListener {
            etEmail.setText(DEMO_GESTOR_EMAIL)
            etPassword.setText(DEMO_GESTOR_PASSWORD)
        }

        btnDemoAdmin.setOnClickListener {
            etEmail.setText(DEMO_ADMIN_EMAIL)
            etPassword.setText(DEMO_ADMIN_PASSWORD)
        }
    }

    private fun performLogin(email: String, password: String) {
        setLoading(true)

        uiScope.launch {
            try {
                // Fase 6: login passa a ser feito directamente no Nexora ERP
                // (nao no FaceClock) — ver ErpLoginRequest/ErpLoginResponse.
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.login(
                        ErpLoginRequest(email = email, password = password)
                    )
                }

                if (!response.isSuccessful || response.body() == null) {
                    Toast.makeText(
                        this@LoginActivity,
                        ApiUtils.errorMessage(response),
                        Toast.LENGTH_LONG
                    ).show()
                    return@launch
                }

                val payload = response.body() ?: return@launch
                val role = RoleUtils.fromErpLogin(payload.tipo, payload.modulos)
                sessionManager.saveSession(
                    token = payload.access_token,
                    refreshToken = payload.refresh_token,
                    userId = payload.user.id.toString(),
                    userName = payload.user.nome,
                    userEmail = payload.user.email,
                    userRole = role,
                    employeeCode = payload.user.email,
                    modulos = payload.modulos
                )
                Toast.makeText(
                    this@LoginActivity,
                    "Login realizado com sucesso.",
                    Toast.LENGTH_SHORT
                ).show()
                SyncAttendanceWorker.schedulePeriodic(this@LoginActivity)
                navigateToMain()
            } catch (_: Exception) {
                Toast.makeText(
                    this@LoginActivity,
                    "Nao foi possivel ligar ao ERP.",
                    Toast.LENGTH_LONG
                ).show()
            } finally {
                setLoading(false)
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        btnLogin.isEnabled = !isLoading
        btnLogin.text = if (isLoading) "A autenticar..." else "Entrar"
    }

    private fun navigateToMain() {
        startActivity(Intent(this, MainActivity::class.java))
        finish()
    }
}
