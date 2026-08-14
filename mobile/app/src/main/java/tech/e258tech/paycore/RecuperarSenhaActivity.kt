package tech.e258tech.paycore

import android.os.Bundle
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.ForgotPasswordRequest

class RecuperarSenhaActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_recuperar_senha)

        val etEmail = findViewById<EditText>(R.id.et_email_recuperar)
        val btnEnviar = findViewById<MaterialButton>(R.id.btn_enviar_link)
        val tvVoltar = findViewById<TextView>(R.id.tv_voltar_login)

        btnEnviar.setOnClickListener {
            val email = etEmail.text.toString().trim()
            if (email.isEmpty() || !android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
                etEmail.error = "Introduza um email válido"
                return@setOnClickListener
            }

            btnEnviar.isEnabled = false
            btnEnviar.text = "A enviar..."

            lifecycleScope.launch {
                try {
                    val response = ApiClient.service.forgotPassword(ForgotPasswordRequest(email))
                    if (response.isSuccessful) {
                        Toast.makeText(
                            this@RecuperarSenhaActivity,
                            "Se o email existir, receberá um link de recuperação.",
                            Toast.LENGTH_LONG
                        ).show()
                        finish()
                    } else {
                        val msg = response.errorBody()?.string()?.takeIf { it.isNotBlank() }
                            ?: "Não foi possível enviar o link. Tente novamente."
                        Toast.makeText(this@RecuperarSenhaActivity, msg, Toast.LENGTH_LONG).show()
                        btnEnviar.isEnabled = true
                        btnEnviar.text = "Enviar link"
                    }
                } catch (e: Exception) {
                    Toast.makeText(
                        this@RecuperarSenhaActivity,
                        "Erro de ligação. Verifique a internet e tente novamente.",
                        Toast.LENGTH_LONG
                    ).show()
                    btnEnviar.isEnabled = true
                    btnEnviar.text = "Enviar link"
                }
            }
        }

        tvVoltar.setOnClickListener { finish() }
    }
}
