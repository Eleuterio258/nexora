package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.CategoriaDTO
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

private data class CategoriaItem(val nome: String, val subtitulo: String, val dto: CategoriaDTO?)

class AdminCategoriasActivity : AppCompatActivity() {

    private val itens = mutableListOf<CategoriaItem>()
    private val adapter = CategoriaAdapter(itens)

    override fun onResume() {
        super.onResume()
        atualizarLista()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Categorias de produtos → /api/produtos/categorias, exige stock:gerir_categorias.
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_STOCK, Permissoes.GERIR_CATEGORIAS)) return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_categorias)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<RecyclerView>(R.id.rv_admin_categorias).apply {
            layoutManager = LinearLayoutManager(this@AdminCategoriasActivity)
            adapter = this@AdminCategoriasActivity.adapter
        }

        findViewById<MaterialButton>(R.id.btn_admin_categorias_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_categoria_nova).setOnClickListener {
            AdminApiRepository.selectedCategoria = null
            startActivity(Intent(this, AdminCategoriaFormActivity::class.java))
        }
    }

    private fun atualizarLista() {
        lifecycleScope.launch {
            AdminApiRepository.loadCategorias()
                .onSuccess { categorias ->
                    exibir(categorias.map { CategoriaItem(it.nome, "Ordem: ${it.ordem}", it) })
                }
                .onFailure {
                    exibir(AdminFixtures.categorias.map {
                        CategoriaItem(it.nome, "${it.totalProdutos} produtos associados", null)
                    })
                }
                .tratarSemPermissao(this@AdminCategoriasActivity)
        }
    }

    private fun exibir(novosItens: List<CategoriaItem>) {
        itens.clear()
        itens.addAll(novosItens)
        adapter.notifyDataSetChanged()

        val vazio = itens.isEmpty()
        findViewById<View>(R.id.rv_admin_categorias).visibility = if (vazio) View.GONE else View.VISIBLE
        findViewById<View>(R.id.layout_categorias_vazio).visibility = if (vazio) View.VISIBLE else View.GONE
    }

    private inner class CategoriaAdapter(
        private val itens: List<CategoriaItem>
    ) : RecyclerView.Adapter<CategoriaAdapter.VH>() {

        inner class VH(view: View) : RecyclerView.ViewHolder(view) {
            val nome: TextView = view.findViewById(R.id.tv_item_categoria_nome)
            val subtitulo: TextView = view.findViewById(R.id.tv_item_categoria_subtitulo)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) = VH(
            LayoutInflater.from(parent.context).inflate(R.layout.item_admin_categoria, parent, false)
        )

        override fun getItemCount() = itens.size

        override fun onBindViewHolder(holder: VH, position: Int) {
            val item = itens[position]
            holder.nome.text = item.nome
            holder.subtitulo.text = item.subtitulo
            holder.itemView.setOnClickListener {
                if (item.dto != null) {
                    AdminApiRepository.selectedCategoria = item.dto
                    startActivity(Intent(this@AdminCategoriasActivity, AdminCategoriaFormActivity::class.java))
                }
            }
        }
    }
}
