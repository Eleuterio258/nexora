package tech.e258tech.paycore

import android.os.Bundle
import android.view.View
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

class AdminCategoriaFormActivity : AppCompatActivity() {

    private val editando = AdminApiRepository.selectedCategoria != null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Criar categoria → POST /api/produtos/categorias, exige stock:gerir_categorias.
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_STOCK, Permissoes.GERIR_CATEGORIAS)) return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_categoria_form)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        preencherFormulario()

        findViewById<TextView>(R.id.tv_admin_categoria_form_titulo).text =
            if (editando) "Editar Categoria" else "Nova Categoria"
        findViewById<MaterialButton>(R.id.btn_admin_categoria_eliminar).visibility =
            if (editando) View.VISIBLE else View.GONE

        findViewById<MaterialButton>(R.id.btn_admin_categoria_form_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_categoria_guardar).setOnClickListener { guardarCategoria() }
        findViewById<MaterialButton>(R.id.btn_admin_categoria_eliminar).setOnClickListener { eliminarCategoria() }
    }

    private fun preencherFormulario() {
        val categoria = AdminApiRepository.selectedCategoria ?: return
        findViewById<TextInputEditText>(R.id.et_admin_categoria_nome).setText(categoria.nome)
        findViewById<TextInputEditText>(R.id.et_admin_categoria_descricao).setText(categoria.descricao ?: "")
        findViewById<TextInputEditText>(R.id.et_admin_categoria_ordem).setText(categoria.ordem.toString())
    }

    private fun guardarCategoria() {
        val nome = findViewById<TextInputEditText>(R.id.et_admin_categoria_nome).text?.toString().orEmpty().trim()
        val descricao = findViewById<TextInputEditText>(R.id.et_admin_categoria_descricao).text?.toString().orEmpty().trim()
        val ordemTexto = findViewById<TextInputEditText>(R.id.et_admin_categoria_ordem).text?.toString().orEmpty().trim()
        val ordem = ordemTexto.toIntOrNull() ?: 0
        val resultado = findViewById<TextView>(R.id.tv_admin_categoria_resultado)

        if (nome.isBlank()) {
            resultado.text = "Informe o nome da categoria."
            return
        }

        resultado.text = "A guardar categoria..."
        lifecycleScope.launch {
            val operation = if (editando) {
                val categoria = AdminApiRepository.selectedCategoria
                if (categoria == null) {
                    resultado.text = "Nenhuma categoria selecionada."
                    return@launch
                }
                AdminApiRepository.updateCategoria(categoria.id, nome, descricao, ordem)
            } else {
                AdminApiRepository.createCategoria(nome, descricao, ordem)
            }

            operation
                .onSuccess { categoria ->
                    val action = if (editando) "actualizada" else "guardada"
                    resultado.text = """
                        Categoria $action via API:
                        ${categoria.nome}
                        Ordem: ${categoria.ordem}
                    """.trimIndent()
                    Toast.makeText(this@AdminCategoriaFormActivity, "Categoria $action via API", Toast.LENGTH_SHORT).show()
                }
                .onFailure {
                    val action = if (editando) "actualizar" else "guardar"
                    resultado.text = "Falha ao $action categoria via API."
                    Toast.makeText(this@AdminCategoriaFormActivity, "Nao foi possivel $action categoria", Toast.LENGTH_SHORT).show()
                }
                .tratarSemPermissao(this@AdminCategoriaFormActivity)
        }
    }

    private fun eliminarCategoria() {
        val resultado = findViewById<TextView>(R.id.tv_admin_categoria_resultado)
        resultado.text = "A eliminar categoria..."
        lifecycleScope.launch {
            AdminApiRepository.deleteSelectedCategoria()
                .onSuccess {
                    resultado.text = "Categoria eliminada via API."
                    Toast.makeText(this@AdminCategoriaFormActivity, "Categoria eliminada", Toast.LENGTH_SHORT).show()
                }
                .onFailure {
                    resultado.text = "Falha ao eliminar categoria."
                    Toast.makeText(this@AdminCategoriaFormActivity, "Nao foi possivel eliminar categoria", Toast.LENGTH_SHORT).show()
                }
                .tratarSemPermissao(this@AdminCategoriaFormActivity)
        }
    }
}
