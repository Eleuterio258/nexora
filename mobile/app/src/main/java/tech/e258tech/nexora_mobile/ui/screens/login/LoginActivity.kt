package tech.e258tech.nexora_mobile.ui.screens.login

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import tech.e258tech.nexora_mobile.BuildConfig
import tech.e258tech.nexora_mobile.app
import tech.e258tech.nexora_mobile.databinding.ActivityLoginBinding
import tech.e258tech.nexora_mobile.ui.screens.main.MainActivity
import tech.e258tech.nexora_mobile.utils.Result

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Pré-preencher credenciais em debug
        if (BuildConfig.DEBUG) {
            binding.etEmail?.setText("eleuterio3d@gmail.com")
            binding.etPassword?.setText("Nexora@2026")
        }

        // Redirecionar se já autenticado
        lifecycleScope.launch {
            if (app.authRepository.isLoggedIn().first()) goToMain()
        }

        binding.btnEnter.setOnClickListener { doLogin() }
    }

    private fun doLogin() {
        val email    = binding.etEmail?.text?.toString()?.trim()    ?: ""
        val password = binding.etPassword?.text?.toString()?.trim() ?: ""

        if (email.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Preencha o email e a senha.", Toast.LENGTH_SHORT).show()
            return
        }

        setLoading(true)

        lifecycleScope.launch {
            when (val result = app.authRepository.login(email, password)) {
                is Result.Success -> goToMain()
                is Result.Error   -> {
                    setLoading(false)
                    Toast.makeText(this@LoginActivity,
                        when (result.code) {
                            401  -> "Email ou senha incorretos."
                            403  -> "Conta sem acesso ao painel."
                            429  -> "Demasiadas tentativas. Aguarde alguns minutos."
                            0    -> result.message
                            else -> "Erro ao iniciar sessão. Tente novamente."
                        }, Toast.LENGTH_LONG).show()
                }
                else -> setLoading(false)
            }
        }
    }

    private fun goToMain() {
        startActivity(Intent(this, MainActivity::class.java))
        finish()
    }

    private fun setLoading(loading: Boolean) {
        binding.btnEnter.isEnabled = !loading
        binding.btnEnter.text = if (loading) "A entrar…" else "Entrar"
    }
}
