package tech.e258tech.paycore

import android.os.Bundle
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
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class AdminDescontoFormActivity : AppCompatActivity() {

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

        setContentView(R.layout.activity_admin_desconto_form)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        preencherFormulario()

        findViewById<MaterialButton>(R.id.btn_admin_desconto_form_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_desconto_guardar).setOnClickListener { guardarDesconto() }
        findViewById<MaterialButton>(R.id.btn_admin_desconto_eliminar).setOnClickListener { eliminarDesconto() }
    }

    private fun preencherFormulario() {
        val desconto = AdminApiRepository.selectedDiscount ?: return
        findViewById<TextInputEditText>(R.id.et_admin_desconto_nome).setText(desconto.name)
        findViewById<TextInputEditText>(R.id.et_admin_desconto_tipo).setText(desconto.type ?: "PERCENTAGE")
        findViewById<TextInputEditText>(R.id.et_admin_desconto_valor).setText((desconto.value ?: 0.0).toString())
        findViewById<TextInputEditText>(R.id.et_admin_desconto_descricao).setText(desconto.description ?: "")
        findViewById<TextInputEditText>(R.id.et_admin_desconto_minimo).setText(desconto.minAmount?.toString().orEmpty())
        findViewById<TextInputEditText>(R.id.et_admin_desconto_maximo).setText(desconto.maxAmount?.toString().orEmpty())
    }

    private fun guardarDesconto() {
        val nome = findViewById<TextInputEditText>(R.id.et_admin_desconto_nome).text?.toString().orEmpty().trim()
        val tipo = findViewById<TextInputEditText>(R.id.et_admin_desconto_tipo).text?.toString().orEmpty().trim().uppercase()
        val valorTexto = findViewById<TextInputEditText>(R.id.et_admin_desconto_valor).text?.toString().orEmpty().trim()
        val descricao = findViewById<TextInputEditText>(R.id.et_admin_desconto_descricao).text?.toString().orEmpty().trim()
        val minimoTexto = findViewById<TextInputEditText>(R.id.et_admin_desconto_minimo).text?.toString().orEmpty().trim()
        val maximoTexto = findViewById<TextInputEditText>(R.id.et_admin_desconto_maximo).text?.toString().orEmpty().trim()
        val resultado = findViewById<TextView>(R.id.tv_admin_desconto_resultado)

        val valor = valorTexto.toDoubleOrNull()
        val minimo = minimoTexto.toDoubleOrNull()
        val maximo = maximoTexto.toDoubleOrNull()

        if (nome.isBlank() || valor == null || tipo !in setOf("PERCENTAGE", "FIXED")) {
            resultado.text = "Preencha nome, tipo valido (PERCENTAGE/FIXED) e valor."
            return
        }

        resultado.text = "A guardar desconto..."
        lifecycleScope.launch {
            AdminApiRepository.saveDiscount(
                name = nome,
                type = tipo,
                value = valor,
                description = descricao,
                minAmount = minimo,
                maxAmount = maximo
            ).onSuccess { desconto ->
                resultado.text = """
                    Desconto guardado via API:
                    ${desconto.name}
                    Tipo: ${desconto.type ?: tipo}
                    Valor: ${desconto.value ?: valor}
                """.trimIndent()
                Toast.makeText(this@AdminDescontoFormActivity, "Desconto guardado via API", Toast.LENGTH_SHORT).show()
            }.onFailure {
                resultado.text = "Falha ao guardar desconto via API."
                Toast.makeText(this@AdminDescontoFormActivity, "Nao foi possivel guardar desconto", Toast.LENGTH_SHORT).show()
            }.tratarSemPermissao(this@AdminDescontoFormActivity)
        }
    }

    private fun eliminarDesconto() {
        val resultado = findViewById<TextView>(R.id.tv_admin_desconto_resultado)
        resultado.text = "A eliminar desconto..."

        lifecycleScope.launch {
            AdminApiRepository.deleteSelectedDiscount()
                .onSuccess {
                    resultado.text = "Desconto eliminado via API."
                    Toast.makeText(this@AdminDescontoFormActivity, "Desconto eliminado", Toast.LENGTH_SHORT).show()
                    finish()
                }
                .onFailure {
                    resultado.text = "Falha ao eliminar desconto."
                    Toast.makeText(this@AdminDescontoFormActivity, "Nao foi possivel eliminar desconto", Toast.LENGTH_SHORT).show()
                }
                .tratarSemPermissao(this@AdminDescontoFormActivity)
        }
    }
}
