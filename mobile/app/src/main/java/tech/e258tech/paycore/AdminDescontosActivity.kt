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

class AdminDescontosActivity : AppCompatActivity() {

    override fun onResume() {
        super.onResume()
        atualizarLista()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.GERIR_DESCONTOS)) return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_descontos)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<MaterialButton>(R.id.btn_admin_descontos_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_desconto_novo).setOnClickListener {
            AdminApiRepository.selectedDiscount = null
            startActivity(Intent(this, AdminDescontoFormActivity::class.java))
        }
        findViewById<MaterialButton>(R.id.btn_admin_desconto_editar).setOnClickListener {
            startActivity(Intent(this, AdminDescontoFormActivity::class.java))
        }
    }

    private fun atualizarLista() {
        val listaView = findViewById<TextView>(R.id.tv_admin_descontos_lista)
        listaView.text = "A carregar descontos..."

        lifecycleScope.launch {
            AdminApiRepository.loadDiscounts()
                .onSuccess { descontos ->
                    listaView.text = if (descontos.isEmpty()) {
                        "Nenhum desconto encontrado."
                    } else {
                        descontos.joinToString("\n\n") { desconto ->
                            buildString {
                                append(desconto.name)
                                append("\n")
                                append("${desconto.type ?: "TIPO"} · ${desconto.value ?: 0.0}")
                                append("\n")
                                append("Estado: ${if (desconto.active == true) "Ativo" else "Inativo"}")
                                desconto.minAmount?.let { append("\nMinimo: ${PosStore.formatarValor(it)}") }
                            }
                        }
                    }
                }
                .onFailure {
                    AdminApiRepository.selectedDiscount = null
                    listaView.text = AdminFixtures.descontos.joinToString("\n\n") { desconto ->
                        "${desconto.nome}\n${desconto.regra}\nEstado: ${desconto.estado}"
                    }
                }
                .tratarSemPermissao(this@AdminDescontosActivity)
        }
    }
}
