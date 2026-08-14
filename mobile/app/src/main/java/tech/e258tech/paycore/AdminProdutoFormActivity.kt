package tech.e258tech.paycore

import android.os.Bundle
import android.view.View
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
import tech.e258tech.paycore.api.CategoriaDTO
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

class AdminProdutoFormActivity : AppCompatActivity() {

    private val editando = AdminApiRepository.selectedProduto != null
    private var categorias: List<CategoriaDTO> = emptyList()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Criar/editar produto → POST/PUT /api/produtos, exige stock:gerir_produtos.
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_STOCK, Permissoes.GERIR_PRODUTOS)) return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_produto_form)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        preencherFormulario()
        carregarCategorias()

        findViewById<TextView>(R.id.tv_admin_produto_form_titulo).text =
            if (editando) "Editar Produto" else "Novo Produto"
        findViewById<MaterialButton>(R.id.btn_admin_produto_guardar).text =
            if (editando) "Guardar alterações" else "Criar produto"
        findViewById<MaterialButton>(R.id.btn_admin_produto_eliminar).visibility =
            if (editando) View.VISIBLE else View.GONE

        findViewById<MaterialButton>(R.id.btn_admin_produto_form_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_produto_guardar).setOnClickListener { guardarProduto() }
        findViewById<MaterialButton>(R.id.btn_admin_produto_eliminar).setOnClickListener { eliminarProduto() }
    }

    private fun preencherFormulario() {
        val produto = AdminApiRepository.selectedProduto ?: return
        findViewById<TextInputEditText>(R.id.et_admin_produto_codigo).apply {
            setText(produto.codigo ?: "")
            // codigo é a chave usada para resolver o produto no update; o
            // backend não tem endpoint para o renomear depois de criado.
            isEnabled = false
        }
        findViewById<TextInputEditText>(R.id.et_admin_produto_nome).setText(produto.nome)
        findViewById<TextInputEditText>(R.id.et_admin_produto_descricao).setText(produto.descricao ?: "")
        findViewById<TextInputEditText>(R.id.et_admin_produto_preco).setText((AdminApiRepository.productPrice(produto)).toString())
        findViewById<TextInputEditText>(R.id.et_admin_produto_barcode).setText(produto.barcode ?: "")
    }

    /** Categoria é um dropdown fechado (só seleção de valores reais do backend, ver
     * AdminApiRepository.loadCategorias) — substitui o antigo campo de texto livre com
     * o ID numérico da categoria, que o utilizador tinha de saber de cor. */
    private fun carregarCategorias() {
        lifecycleScope.launch {
            AdminApiRepository.loadCategorias().onSuccess { lista ->
                categorias = lista
                val etCategoria = findViewById<AutoCompleteTextView>(R.id.et_admin_produto_categoria)
                etCategoria.setAdapter(
                    ArrayAdapter(this@AdminProdutoFormActivity, android.R.layout.simple_dropdown_item_1line, lista.map { it.nome })
                )
                val categoriaAtual = AdminApiRepository.selectedProduto?.categoriaId
                    ?.let { id -> lista.firstOrNull { it.id == id } }
                if (categoriaAtual != null) etCategoria.setText(categoriaAtual.nome, false)
            }
        }
    }

    private fun guardarProduto() {
        val codigo = findViewById<TextInputEditText>(R.id.et_admin_produto_codigo).text?.toString().orEmpty().trim()
        val nome = findViewById<TextInputEditText>(R.id.et_admin_produto_nome).text?.toString().orEmpty().trim()
        val categoriaNome = findViewById<AutoCompleteTextView>(R.id.et_admin_produto_categoria).text?.toString().orEmpty().trim()
        val categoriaId = categorias.firstOrNull { it.nome == categoriaNome }?.id
        val descricao = findViewById<TextInputEditText>(R.id.et_admin_produto_descricao).text?.toString().orEmpty().trim()
        val precoTexto = findViewById<TextInputEditText>(R.id.et_admin_produto_preco).text?.toString().orEmpty().trim()
        val barcode = findViewById<TextInputEditText>(R.id.et_admin_produto_barcode).text?.toString().orEmpty().trim()
        val resultado = findViewById<TextView>(R.id.tv_admin_produto_resultado)
        val preco = precoTexto.toDoubleOrNull()

        if (codigo.isBlank() || nome.isBlank() || preco == null) {
            resultado.text = "Preencha pelo menos código, nome e preço válido."
            return
        }

        resultado.text = "A guardar produto..."
        lifecycleScope.launch {
            AdminApiRepository.saveProduto(
                codigo = codigo,
                nome = nome,
                categoriaId = categoriaId,
                descricao = descricao,
                preco = preco,
                barcode = barcode
            ).onSuccess { produto ->
                resultado.text = """
                    Produto guardado via API:
                    ${produto.nome}
                    Categoria: ${produto.categoriaNome ?: produto.categoriaId ?: "N/D"}
                    Preco: ${PosStore.formatarValor(AdminApiRepository.productPrice(produto))}
                """.trimIndent()
                Toast.makeText(this@AdminProdutoFormActivity, "Produto guardado via API", Toast.LENGTH_SHORT).show()
            }.onFailure {
                resultado.text = "Falha ao guardar produto via API."
                Toast.makeText(this@AdminProdutoFormActivity, "Nao foi possivel guardar produto", Toast.LENGTH_SHORT).show()
            }.tratarSemPermissao(this@AdminProdutoFormActivity)
        }
    }

    private fun eliminarProduto() {
        val resultado = findViewById<TextView>(R.id.tv_admin_produto_resultado)
        resultado.text = "A eliminar produto..."
        lifecycleScope.launch {
            AdminApiRepository.deleteSelectedProduto()
                .onSuccess {
                    resultado.text = "Produto eliminado via API."
                    Toast.makeText(this@AdminProdutoFormActivity, "Produto eliminado", Toast.LENGTH_SHORT).show()
                }
                .onFailure {
                    resultado.text = "Falha ao eliminar produto."
                    Toast.makeText(this@AdminProdutoFormActivity, "Nao foi possivel eliminar produto", Toast.LENGTH_SHORT).show()
                }
                .tratarSemPermissao(this@AdminProdutoFormActivity)
        }
    }
}
