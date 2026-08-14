package tech.e258tech.paycore

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
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper

class AdminCaixaActivity : AppCompatActivity() {

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

        setContentView(R.layout.activity_admin_caixa)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<MaterialButton>(R.id.btn_admin_caixa_voltar).setOnClickListener { finish() }
    }

    private fun atualizarLista() {
        val listaView = findViewById<TextView>(R.id.tv_admin_caixa_lista)
        listaView.text = "A carregar caixas..."

        lifecycleScope.launch {
            AdminApiRepository.loadCashDrawers()
                .onSuccess { caixas ->
                    listaView.text = if (caixas.isEmpty()) {
                        "Nenhum caixa encontrado."
                    } else {
                        caixas.joinToString("\n\n") { caixa ->
                            val total = caixa.closingAmount ?: caixa.openingAmount ?: 0.0
                            "Terminal #${caixa.terminalId}\nAbertura: ${caixa.openedAt ?: "N/D"} · Fecho: ${caixa.closedAt ?: "Em aberto"}\nStatus: ${caixa.status ?: "N/D"} · Total: ${PosStore.formatarValor(total)}"
                        }
                    }
                }
                .onFailure {
                    listaView.text = AdminFixtures.caixas.joinToString("\n\n") { caixa ->
                        "${caixa.operador}\nAbertura: ${caixa.abertura} · Fecho: ${caixa.fecho}\nTotal: ${PosStore.formatarValor(caixa.total)}"
                    }
                }
                .tratarSemPermissao(this@AdminCaixaActivity)
        }
    }
}
