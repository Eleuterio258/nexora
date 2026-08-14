package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.utils.PermissaoHelper
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao

class AdminUtilizadoresActivity : AppCompatActivity() {


    override fun onResume() {
        super.onResume()
        atualizarLista()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Gate pela permissão real do ERP (autorizacao:gerir_utilizadores), não
        // por uma string de "role" — no ERP não existe tipo "admin"; um
        // funcionário admin tem tipo=funcionario + cargo com esta permissão.
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

        setContentView(R.layout.activity_admin_utilizadores)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<MaterialButton>(R.id.btn_admin_utilizadores_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_utilizador_novo).setOnClickListener {
            startActivity(Intent(this, AdminUtilizadorFormActivity::class.java))
        }
    }

    private fun atualizarLista() {
        val listaView = findViewById<TextView>(R.id.tv_admin_utilizadores_lista)
        listaView.text = "A carregar utilizadores..."

        lifecycleScope.launch {
            AdminApiRepository.loadUsers()
                .onSuccess { users ->
                    listaView.text = if (users.isEmpty()) {
                        "Nenhum utilizador encontrado."
                    } else {
                        users.joinToString("\n\n") { user ->
                            "${user.name}\n${user.role} · ${user.email}\nTelefone: ${user.phoneNumber ?: "N/D"}"
                        }
                    }
                }
                .onFailure {
                    listaView.text = AdminFixtures.utilizadores.joinToString("\n\n") { utilizador ->
                        "${utilizador.nome}\n${utilizador.role} · ${utilizador.email}"
                    }
                }
                .tratarSemPermissao(this@AdminUtilizadoresActivity)
        }
    }
}



