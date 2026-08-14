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
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.api.ProdutoDTO
import tech.e258tech.paycore.utils.PermissaoHelper.tratarSemPermissao
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar

private data class ProdutoItem(val nome: String, val subtitulo: String, val dto: ProdutoDTO?)

class AdminProdutosActivity : AppCompatActivity() {

    private val itens = mutableListOf<ProdutoItem>()
    private val adapter = ProdutoAdapter(itens)

    override fun onResume() {
        super.onResume()
        atualizarLista()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Listar produtos usa GET /api/produtos → o ERP exige stock:ver_stock.
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_STOCK, Permissoes.VER_STOCK)) return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.WHITE
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setContentView(R.layout.activity_admin_produtos)

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.layout_header)) { view, insets ->
            val sb = insets.getInsets(WindowInsetsCompat.Type.statusBars())
            view.setPadding(view.paddingLeft, sb.top, view.paddingRight, view.paddingBottom)
            insets
        }

        findViewById<RecyclerView>(R.id.rv_admin_produtos).apply {
            layoutManager = LinearLayoutManager(this@AdminProdutosActivity)
            adapter = this@AdminProdutosActivity.adapter
        }

        findViewById<MaterialButton>(R.id.btn_admin_produtos_voltar).setOnClickListener { finish() }
        findViewById<MaterialButton>(R.id.btn_admin_produto_novo).setOnClickListener {
            AdminApiRepository.selectedProduto = null
            startActivity(Intent(this, AdminProdutoFormActivity::class.java))
        }
    }

    private fun atualizarLista() {
        lifecycleScope.launch {
            AdminApiRepository.loadProdutos()
                .onSuccess { produtos ->
                    exibir(produtos.map {
                        val categoria = it.categoriaNome ?: "Sem categoria"
                        val preco = PosStore.formatarValor(AdminApiRepository.productPrice(it))
                        ProdutoItem(it.nome, "$categoria · $preco", it)
                    })
                }
                .onFailure {
                    exibir(AdminFixtures.produtos.map {
                        ProdutoItem(it.nome, "${it.categoria} · ${PosStore.formatarValor(it.preco)} · Stock: ${it.stock}", null)
                    })
                }
                .tratarSemPermissao(this@AdminProdutosActivity)
        }
    }

    private fun exibir(novosItens: List<ProdutoItem>) {
        itens.clear()
        itens.addAll(novosItens)
        adapter.notifyDataSetChanged()

        val vazio = itens.isEmpty()
        findViewById<View>(R.id.rv_admin_produtos).visibility = if (vazio) View.GONE else View.VISIBLE
        findViewById<View>(R.id.layout_produtos_vazio).visibility = if (vazio) View.VISIBLE else View.GONE
    }

    private inner class ProdutoAdapter(
        private val itens: List<ProdutoItem>
    ) : RecyclerView.Adapter<ProdutoAdapter.VH>() {

        inner class VH(view: View) : RecyclerView.ViewHolder(view) {
            val nome: TextView = view.findViewById(R.id.tv_item_produto_nome)
            val subtitulo: TextView = view.findViewById(R.id.tv_item_produto_subtitulo)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) = VH(
            LayoutInflater.from(parent.context).inflate(R.layout.item_admin_produto, parent, false)
        )

        override fun getItemCount() = itens.size

        override fun onBindViewHolder(holder: VH, position: Int) {
            val item = itens[position]
            holder.nome.text = item.nome
            holder.subtitulo.text = item.subtitulo
            holder.itemView.setOnClickListener {
                if (item.dto != null) {
                    AdminApiRepository.selectedProduto = item.dto
                    startActivity(Intent(this@AdminProdutosActivity, AdminProdutoFormActivity::class.java))
                }
            }
        }
    }
}
