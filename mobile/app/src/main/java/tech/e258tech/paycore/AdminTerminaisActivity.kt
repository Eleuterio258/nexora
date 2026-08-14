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
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class AdminTerminaisActivity : AppCompatActivity() {

    override fun onResume() {
        super.onResume()
        atualizarLista()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.GERIR_TERMINAIS)) return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_terminais)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<MaterialButton>(R.id.btn_admin_terminais_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_terminal_novo).setOnClickListener {
            startActivity(Intent(this, AdminTerminalCriarActivity::class.java))
        }
        findViewById<MaterialButton>(R.id.btn_admin_terminal_detalhe).setOnClickListener {
            startActivity(Intent(this, AdminTerminalDetalheActivity::class.java))
        }
    }

    private fun atualizarLista() {
        val listaView = findViewById<TextView>(R.id.tv_admin_terminais_lista)
        listaView.text = "A carregar terminais..."

        lifecycleScope.launch {
            AdminApiRepository.loadTerminais()
                .onSuccess { terminais ->
                    AdminApiRepository.selectedTerminal = terminais.firstOrNull()
                    listaView.text = if (terminais.isEmpty()) {
                        "Nenhum terminal encontrado."
                    } else {
                        terminais.joinToString("\n\n") { terminal ->
                            "${AdminApiRepository.terminalTitle(terminal)}\nCodigo: ${terminal.codigo ?: "N/D"}\nEstado: ${AdminApiRepository.terminalStatus(terminal)} · Ativacao: ${terminal.activationCode ?: "N/D"}"
                        }
                    }
                }
                .onFailure {
                    listaView.text = AdminFixtures.terminais.joinToString("\n\n") { terminal ->
                        "${terminal.nome}\nSerial: ${terminal.serial}\nEstado: ${terminal.estado} · Codigo: ${terminal.activationCode}"
                    }
                }
                .tratarSemPermissao(this@AdminTerminaisActivity)
        }
    }
}
