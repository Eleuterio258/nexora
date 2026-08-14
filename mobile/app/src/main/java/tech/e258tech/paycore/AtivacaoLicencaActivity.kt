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
import tech.e258tech.paycore.api.ValidarLicencaRequest
import tech.e258tech.paycore.ui.LoginTerminalActivity

class AtivacaoLicencaActivity : AppCompatActivity() {

    companion object {
        // Chave de demo — mantida como fallback offline apenas para desenvolvimento.
        private const val CHAVE_DEMO = "PAYS-CORE-2026-DEMO"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ativacao_licenca)

        val etChave = findViewById<EditText>(R.id.et_chave_licenca)
        val btnValidar = findViewById<MaterialButton>(R.id.btn_validar_licenca)

        // Formatar automaticamente XXXX-XXXX-XXXX-XXXX ao digitar
        etChave.addTextChangedListener(object : android.text.TextWatcher {
            private var editing = false
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: android.text.Editable?) {
                if (editing || s == null) return
                editing = true
                val digits = s.toString().replace("-", "").uppercase()
                val formatted = buildString {
                    digits.forEachIndexed { i, c ->
                        if (i > 0 && i % 4 == 0 && i < 16) append('-')
                        append(c)
                    }
                }
                s.replace(0, s.length, formatted.take(19))
                editing = false
            }
        })

        btnValidar.setOnClickListener {
            val chave = etChave.text.toString().trim()
            when {
                chave.isEmpty() -> {
                    etChave.error = "Introduza a chave de licença"
                }
                chave.length < 19 -> {
                    etChave.error = "Chave incompleta"
                }
                chave == CHAVE_DEMO && tech.e258tech.paycore.BuildConfig.DEBUG -> {
                    // Fallback offline para desenvolvimento/demo — só em builds de debug,
                    // nunca um bypass válido numa build de produção assinada.
                    Toast.makeText(this, "Licença demo activada!", Toast.LENGTH_SHORT).show()
                    startActivity(Intent(this, LoginActivity::class.java))
                    finish()
                }
                else -> {
                    btnValidar.isEnabled = false
                    lifecycleScope.launch {
                        try {
                            val response = ApiClient.service.validarLicencaApp(ValidarLicencaRequest(chave))
                            val body = response.body()
                            if (response.isSuccessful && body?.valida == true) {
                                // Guardar tenant devolvido para usar no login do terminal
                                body.tenantId?.let { tenantId ->
                                    getSharedPreferences(LoginTerminalActivity.PREFS_TERMINAL, MODE_PRIVATE)
                                        .edit()
                                        .putString(LoginTerminalActivity.KEY_TENANT_ID, tenantId.toString())
                                        .putString(LoginTerminalActivity.KEY_TENANT_NOME, body.tenantNome ?: "")
                                        .apply()
                                }
                                Toast.makeText(this@AtivacaoLicencaActivity, "Licença activada com sucesso!", Toast.LENGTH_SHORT).show()
                                startActivity(Intent(this@AtivacaoLicencaActivity, LoginActivity::class.java))
                                finish()
                            } else {
                                val msg = body?.motivo ?: "Chave de licença inválida"
                                Toast.makeText(this@AtivacaoLicencaActivity, msg, Toast.LENGTH_LONG).show()
                                btnValidar.isEnabled = true
                            }
                        } catch (e: Exception) {
                            Toast.makeText(
                                this@AtivacaoLicencaActivity,
                                "Erro de ligação. Tente novamente ou use a chave demo.",
                                Toast.LENGTH_LONG
                            ).show()
                            btnValidar.isEnabled = true
                        }
                    }
                }
            }
        }
    }
}
