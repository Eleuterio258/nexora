package tech.e258tech.paycore

import android.os.Bundle
import android.util.Patterns
import android.widget.ArrayAdapter
import android.widget.AutoCompleteTextView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputEditText
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.PermissaoHelper
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao

class AdminUtilizadorFormActivity : AppCompatActivity() {

    // Sugestões — não é uma lista fechada: o ERP modela isto como cargo, configurável por
    // tenant (ver comentário em AdminUtilizadoresActivity), por isso o campo continua a
    // aceitar texto livre. Mesmos valores de referência usados em SessionRepository.perfilPorRole.
    private val cargosSugeridos = listOf("super_admin", "admin", "manager", "operador", "supervisor", "gerente")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Gate pela permissão real do ERP (autorizacao:gerir_utilizadores) — ver
        // nota em AdminUtilizadoresActivity.
        val podeEntrar = SessionRepository.temPermissao(Permissoes.MODULO_AUTORIZACAO, Permissoes.GERIR_UTILIZADORES)
        if (!podeEntrar) {
            PermissaoHelper.mostrarSemPermissaoEFechar(this)
            return
        }
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_utilizador_form)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<AutoCompleteTextView>(R.id.et_admin_utilizador_role).setAdapter(
            ArrayAdapter(this, android.R.layout.simple_dropdown_item_1line, cargosSugeridos)
        )
        preencherFormulario()

        findViewById<MaterialButton>(R.id.btn_admin_utilizador_form_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_utilizador_guardar).setOnClickListener { guardarUtilizador() }
        findViewById<MaterialButton>(R.id.btn_admin_utilizador_eliminar).setOnClickListener { eliminarUtilizador() }
    }

    private fun preencherFormulario() {
        val user = AdminApiRepository.selectedUser ?: return
        findViewById<TextInputEditText>(R.id.et_admin_utilizador_nome).setText(user.name)
        findViewById<TextInputEditText>(R.id.et_admin_utilizador_email).setText(user.email)
        findViewById<AutoCompleteTextView>(R.id.et_admin_utilizador_role).setText(user.role.orEmpty(), false)
        findViewById<TextInputEditText>(R.id.et_admin_utilizador_phone).setText(user.phoneNumber ?: "")
    }

    private fun guardarUtilizador() {
        val nome = findViewById<TextInputEditText>(R.id.et_admin_utilizador_nome).text?.toString().orEmpty().trim()
        val email = findViewById<TextInputEditText>(R.id.et_admin_utilizador_email).text?.toString().orEmpty().trim()
        val role = findViewById<AutoCompleteTextView>(R.id.et_admin_utilizador_role).text?.toString().orEmpty().trim()
        val password = findViewById<TextInputEditText>(R.id.et_admin_utilizador_password).text?.toString().orEmpty().trim()
        val phone = findViewById<TextInputEditText>(R.id.et_admin_utilizador_phone).text?.toString().orEmpty().trim()
        val resultado = findViewById<TextView>(R.id.tv_admin_utilizador_resultado)

        if (nome.isBlank() || email.isBlank()) {
            resultado.text = "Preencha nome e email."
            return
        }
        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            resultado.text = "Email inválido."
            return
        }
        if (AdminApiRepository.selectedUser == null && password.length < 6) {
            resultado.text = "Para novo utilizador, password minima de 6 caracteres."
            return
        }

        resultado.text = "A guardar utilizador..."
        lifecycleScope.launch {
            AdminApiRepository.saveUser(email, nome, password.ifBlank { null }, role, phone)
                .onSuccess { user ->
                    resultado.text = """
                        Utilizador guardado via API:
                        ${user.name}
                        ${user.email}
                        Role: ${user.role}
                    """.trimIndent()
                    Toast.makeText(this@AdminUtilizadorFormActivity, "Utilizador guardado via API", Toast.LENGTH_SHORT).show()
                }
                .onFailure {
                    resultado.text = "Falha ao guardar utilizador via API."
                    Toast.makeText(this@AdminUtilizadorFormActivity, "Nao foi possivel guardar utilizador", Toast.LENGTH_SHORT).show()
                }
                .tratarSemPermissao(this@AdminUtilizadorFormActivity)
        }
    }

    private fun eliminarUtilizador() {
        val resultado = findViewById<TextView>(R.id.tv_admin_utilizador_resultado)
        resultado.text = "A eliminar utilizador..."
        lifecycleScope.launch {
            AdminApiRepository.deleteSelectedUser()
                .onSuccess {
                    resultado.text = "Utilizador eliminado via API."
                    Toast.makeText(this@AdminUtilizadorFormActivity, "Utilizador eliminado", Toast.LENGTH_SHORT).show()
                }
                .onFailure {
                    resultado.text = "Falha ao eliminar utilizador."
                    Toast.makeText(this@AdminUtilizadorFormActivity, "Nao foi possivel eliminar utilizador", Toast.LENGTH_SHORT).show()
                }
                .tratarSemPermissao(this@AdminUtilizadorFormActivity)
        }
    }
}
