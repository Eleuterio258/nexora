package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.view.inputmethod.EditorInfo
import android.widget.EditText
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
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class AdminTransacoesActivity : AppCompatActivity() {


    override fun onResume() {
        super.onResume()
        atualizarLista()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val podeEntrar = SessionRepository.temPermissao(Permissoes.MODULO_POS, Permissoes.OPERAR_POS) ||
                         SessionRepository.temPermissaoAdmin()
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

        setContentView(R.layout.activity_admin_transacoes)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<MaterialButton>(R.id.btn_admin_transacoes_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_ir_relatorio).setOnClickListener {
            startActivity(Intent(this, AdminRelatorioActivity::class.java))
        }
        findViewById<EditText>(R.id.et_admin_transacoes_busca).setOnEditorActionListener { view, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                atualizarLista(view.text?.toString())
                true
            } else {
                false
            }
        }
    }

    private fun atualizarLista(busca: String? = null) {
        val listaView = findViewById<TextView>(R.id.tv_admin_transacoes_lista)
        listaView.text = "A carregar transacoes..."

        lifecycleScope.launch {
            AdminApiRepository.loadTransacoes(busca)
                .onSuccess { transacoes ->
                    listaView.text = if (transacoes.isEmpty()) {
                        "Nenhuma transacao encontrada."
                    } else {
                        transacoes.joinToString("\n\n") { transacao ->
                            val total = transacao.total ?: 0.0
                            val data = transacao.soldAt ?: transacao.createdAt ?: "Data indisponivel"
                            "${transacao.referencia}\n$data\nEstado: ${transacao.estado} · ${PosStore.formatarValor(total)}"
                        }
                    }
                }
                .onFailure {
                    listaView.text = AdminFixtures.transacoes.joinToString("\n\n") { transacao ->
                        "${transacao.referencia}\n${transacao.metodo} · ${transacao.data}\nEstado: ${transacao.estado} · ${PosStore.formatarValor(transacao.total)}"
                    }
                }
                .tratarSemPermissao(this@AdminTransacoesActivity)
        }
    }
}


