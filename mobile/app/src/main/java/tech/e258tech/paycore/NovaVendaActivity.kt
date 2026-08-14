package tech.e258tech.paycore

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.doAfterTextChanged
import androidx.lifecycle.ViewModelProvider
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.textfield.TextInputEditText
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.ProdutoCatalogo
import tech.e258tech.paycore.utils.PermissaoHelper.verificarPermissaoOuFechar
import tech.e258tech.paycore.viewmodel.ApplicationViewModelFactory
import tech.e258tech.paycore.viewmodel.NovaVendaViewModel

class NovaVendaActivity : AppCompatActivity() {

    private val viewModel by lazy {
        ViewModelProvider(this, ApplicationViewModelFactory { NovaVendaViewModel(application) })[NovaVendaViewModel::class.java]
    }

    private val scannerLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val codigo = result.data?.getStringExtra(ScannerActivity.EXTRA_BARCODE).orEmpty()
            if (codigo.isNotEmpty()) {
                val produto = catalogoCompleto.firstOrNull { it.barcode == codigo }
                if (produto != null) {
                    if (viewModel.adicionarItem(produto.nome, produto.preco, produto.imagem, produto.id)) {
                        atualizarCarrinho()
                    } else {
                        Toast.makeText(this, "Sem stock disponível", Toast.LENGTH_SHORT).show()
                    }
                } else {
                    Toast.makeText(this, "Código não encontrado: $codigo", Toast.LENGTH_SHORT).show()
                    etPesquisa.setText(codigo)
                }
            }
        }
    }

    private lateinit var rvProdutos: RecyclerView
    private lateinit var tvSubtotal: TextView
    private lateinit var tvTotal: TextView
    private lateinit var tvVazio: TextView
    private lateinit var tvItensCount: TextView
    private lateinit var btnPagar: MaterialButton
    private lateinit var layoutCategorias: LinearLayout
    private lateinit var produtoAdapter: ProdutoAdapter
    private lateinit var etPesquisa: TextInputEditText

    private var catalogoCompleto = emptyList<ProdutoCatalogo>()
    private var categoriaSelecionada = "Todos"
    private var termoPesquisa = ""

    override fun onResume() {
        super.onResume()
        atualizarCarrinho()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!verificarPermissaoOuFechar(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)) return
        setContentView(R.layout.activity_nova_venda)

        findViewById<android.widget.ImageButton>(R.id.btn_voltar).setOnClickListener { finish() }
        findViewById<android.widget.ImageButton>(R.id.btn_notificacoes).setOnClickListener {
            startActivity(android.content.Intent(this, NotificacoesActivity::class.java))
        }

        rvProdutos = findViewById(R.id.rv_produtos)
        tvSubtotal = findViewById(R.id.tv_venda_subtotal)
        tvTotal = findViewById(R.id.tv_venda_total)
        tvVazio = findViewById(R.id.tv_venda_vazio)
        tvItensCount = findViewById(R.id.tv_itens_count)
        btnPagar = findViewById(R.id.btn_pagar_venda)
        layoutCategorias = findViewById(R.id.layout_categorias)
        etPesquisa = findViewById(R.id.et_pesquisa)

        produtoAdapter = ProdutoAdapter { produto ->
            if (viewModel.adicionarItem(produto.nome, produto.preco, produto.imagem, produto.id)) {
                atualizarCarrinho()
            } else {
                Toast.makeText(this, "Sem stock disponível", Toast.LENGTH_SHORT).show()
            }
        }
        rvProdutos.adapter = produtoAdapter

        viewModel.carregarCatalogoAsync { cats, prods ->
            runOnUiThread {
                catalogoCompleto = prods
                configurarCategorias(cats)
                aplicarFiltro()
            }
        }

        etPesquisa.doAfterTextChanged { editable ->
            termoPesquisa = editable?.toString().orEmpty().trim()
            aplicarFiltro()
        }

        findViewById<android.widget.ImageButton>(R.id.btn_scanner_barcode).setOnClickListener {
            scannerLauncher.launch(Intent(this, ScannerActivity::class.java))
        }

        // pesquisa manual por teclado
        etPesquisa.setOnEditorActionListener { _, _, _ ->
            val codigo = etPesquisa.text?.toString().orEmpty().trim()
            if (codigo.isEmpty()) return@setOnEditorActionListener false
            val produto = catalogoCompleto.firstOrNull { it.barcode == codigo }
            if (produto != null) {
                if (viewModel.adicionarItem(produto.nome, produto.preco, produto.imagem, produto.id)) {
                    atualizarCarrinho()
                    etPesquisa.setText("")
                } else {
                    Toast.makeText(this, "Sem stock disponível", Toast.LENGTH_SHORT).show()
                }
            } else {
                Toast.makeText(this, "Código não encontrado", Toast.LENGTH_SHORT).show()
            }
            true
        }

        tvItensCount.setOnClickListener { mostrarCarrinho() }


        findViewById<MaterialButton>(R.id.btn_limpar_venda).setOnClickListener {
            viewModel.limparVendaAtual()
            atualizarCarrinho()
        }

        findViewById<MaterialButton>(R.id.btn_guardar_pedido).setOnClickListener {
            if (!viewModel.podePagarVendaAtual()) return@setOnClickListener
            viewModel.guardarPedidoAtual()
            atualizarCarrinho()
            Toast.makeText(this, "Pedido guardado", Toast.LENGTH_SHORT).show()
        }

        btnPagar.setOnClickListener {
            if (!viewModel.podePagarVendaAtual()) return@setOnClickListener
            // sessaoAtualLocalId (não sessaoAtualId, que só existe depois de sincronizar) —
            // uma caixa aberta offline também deve permitir vender.
            if (PosStore.sessaoAtualLocalId == null) {
                startActivity(Intent(this, AberturaCaixaActivity::class.java))
            } else {
                startActivity(Intent(this, PagamentoActivity::class.java))
            }
        }
    }

    private fun configurarCategorias(categorias: List<String>) {
        layoutCategorias.removeAllViews()

        categorias.forEachIndexed { index, categoria ->
            val botao = MaterialButton(this, null, com.google.android.material.R.attr.materialButtonOutlinedStyle).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    36.dp()
                ).also { params ->
                    if (index > 0) params.marginStart = 8.dp()
                }
                text = categoria
                isAllCaps = false
                cornerRadius = 18.dp()
                strokeColor = getColorStateList(R.color.divider)
                setOnClickListener {
                    categoriaSelecionada = categoria
                    atualizarEstadoCategorias()
                    aplicarFiltro()
                }
            }
            layoutCategorias.addView(botao)
        }

        atualizarEstadoCategorias()
    }

    private fun atualizarEstadoCategorias() {
        for (index in 0 until layoutCategorias.childCount) {
            val child = layoutCategorias.getChildAt(index)
            if (child is MaterialButton) {
                val selecionado = child.text.toString() == categoriaSelecionada
                child.backgroundTintList = getColorStateList(
                    if (selecionado) R.color.colorPrimary else R.color.white
                )
                child.setTextColor(getColor(if (selecionado) R.color.white else R.color.text_primary))
                child.strokeWidth = if (selecionado) 0 else 1.dp()
            }
        }
    }

    private fun aplicarFiltro() {
        val filtrados = catalogoCompleto.filter {
            val categoriaOk = categoriaSelecionada == "Todos" || it.categoria == categoriaSelecionada
            val pesquisaOk = termoPesquisa.isBlank() ||
                it.nome.contains(termoPesquisa, ignoreCase = true) ||
                it.barcode.contains(termoPesquisa, ignoreCase = true)
            categoriaOk && pesquisaOk
        }
        produtoAdapter.atualizar(filtrados)
        tvVazio.visibility = if (filtrados.isEmpty()) View.VISIBLE else View.GONE
    }

    private fun atualizarCarrinho() {
        val itens = viewModel.itensVendaAtual()
        val totalItens = itens.sumOf { it.quantidade }
        tvItensCount.text = "$totalItens ${if (totalItens == 1) "item" else "itens"} no carrinho  >"
        tvSubtotal.text = PosStore.formatarValor(viewModel.subtotalVendaAtual())
        tvTotal.text = PosStore.formatarValor(viewModel.totalVendaAtual())
        btnPagar.isEnabled = viewModel.podePagarVendaAtual()
    }

    private fun mostrarCarrinho() {
        val sheet = BottomSheetDialog(this)
        val sheetView = layoutInflater.inflate(R.layout.bottom_sheet_carrinho, null)
        sheet.setContentView(sheetView)
        sheet.setOnShowListener {
            val bottomSheet = sheet.findViewById<View>(com.google.android.material.R.id.design_bottom_sheet)
            bottomSheet?.let {
                it.layoutParams.height = resources.displayMetrics.heightPixels
                it.requestLayout()
            }
            sheet.behavior.apply {
                isFitToContents = true
                skipCollapsed   = true
                state           = BottomSheetBehavior.STATE_EXPANDED
            }
        }

        val rvCarrinho = sheetView.findViewById<RecyclerView>(R.id.rv_carrinho)
        val tvVazioSheet = sheetView.findViewById<TextView>(R.id.tv_carrinho_vazio)
        val tvTotalSheet = sheetView.findViewById<TextView>(R.id.tv_carrinho_total)
        val btnPagarSheet = sheetView.findViewById<MaterialButton>(R.id.btn_carrinho_pagar)
        val btnLimparSheet = sheetView.findViewById<MaterialButton>(R.id.btn_limpar_carrinho)

        fun refresh() {
            val itens = viewModel.itensVendaAtual()
            tvVazioSheet.visibility = if (itens.isEmpty()) View.VISIBLE else View.GONE
            rvCarrinho.visibility = if (itens.isEmpty()) View.GONE else View.VISIBLE
            tvTotalSheet.text = PosStore.formatarValor(viewModel.totalVendaAtual())
            btnPagarSheet.isEnabled = viewModel.podePagarVendaAtual()
            rvCarrinho.adapter?.notifyDataSetChanged()
            atualizarCarrinho()
        }

        rvCarrinho.adapter = CarrinhoAdapter(
            onIncrementar = { pos ->
                val item = viewModel.itensVendaAtual()[pos]
                if (viewModel.incrementarItem(item.nome, item.produtoId)) {
                    refresh()
                } else {
                    Toast.makeText(this, "Sem stock disponível", Toast.LENGTH_SHORT).show()
                }
            },
            onDecrementar = { pos ->
                val item = viewModel.itensVendaAtual()[pos]
                viewModel.decrementarItem(item.nome, item.produtoId)
                refresh()
                if (viewModel.itensVendaAtual().isEmpty()) sheet.dismiss()
            }
        )

        btnLimparSheet.setOnClickListener {
            viewModel.limparVendaAtual()
            atualizarCarrinho()
            sheet.dismiss()
        }

        btnPagarSheet.setOnClickListener {
            sheet.dismiss()
            // sessaoAtualLocalId (não sessaoAtualId, que só existe depois de sincronizar) —
            // uma caixa aberta offline também deve permitir vender.
            if (PosStore.sessaoAtualLocalId == null) {
                startActivity(Intent(this, AberturaCaixaActivity::class.java))
            } else {
                startActivity(Intent(this, PagamentoActivity::class.java))
            }
        }

        refresh()
        sheet.show()
    }

    private inner class ProdutoAdapter(
        private val onAdd: (ProdutoCatalogo) -> Unit
    ) : RecyclerView.Adapter<ProdutoAdapter.VH>() {

        private val itens = mutableListOf<ProdutoCatalogo>()

        inner class VH(view: View) : RecyclerView.ViewHolder(view) {
            val ivImagem: ImageView = view.findViewById(R.id.iv_produto_imagem)
            val tvNome: TextView = view.findViewById(R.id.tv_produto_nome)
            val tvPreco: TextView = view.findViewById(R.id.tv_produto_preco)
            val btnAdd: FrameLayout = view.findViewById(R.id.btn_adicionar)
            val card: MaterialCardView = view as MaterialCardView
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) = VH(
            LayoutInflater.from(parent.context).inflate(R.layout.item_produto, parent, false)
        )

        override fun getItemCount() = itens.size

        fun atualizar(novosItens: List<ProdutoCatalogo>) {
            itens.clear()
            itens.addAll(novosItens)
            notifyDataSetChanged()
        }

        override fun onBindViewHolder(holder: VH, position: Int) {
            val produto = itens[position]
            holder.tvNome.text  = produto.nome
            holder.tvPreco.text = PosStore.formatarValor(produto.preco)
            when {
                produto.drawableRes != null ->
                    holder.ivImagem.setImageResource(produto.drawableRes)
                produto.imagemLocal != null || !produto.imagem.isNullOrBlank() ->
                    RemoteImageLoader.load(holder.ivImagem, produto.imagemLocal, produto.imagem)
                else ->
                    holder.ivImagem.setImageDrawable(null)
            }
            holder.btnAdd.setOnClickListener { onAdd(produto) }
            holder.card.setOnClickListener { onAdd(produto) }
        }
    }

    private inner class CarrinhoAdapter(
        private val onIncrementar: (Int) -> Unit,
        private val onDecrementar: (Int) -> Unit
    ) : RecyclerView.Adapter<CarrinhoAdapter.VH>() {

        inner class VH(view: View) : RecyclerView.ViewHolder(view) {
            val ivImagem: ImageView = view.findViewById(R.id.iv_carrinho_imagem)
            val tvQtd: TextView = view.findViewById(R.id.tv_carrinho_qtd)
            val tvNome: TextView = view.findViewById(R.id.tv_carrinho_nome)
            val tvPreco: TextView = view.findViewById(R.id.tv_carrinho_preco)
            val btnIncrementar: MaterialButton = view.findViewById(R.id.btn_incrementar_item)
            val btnDecrementar: MaterialButton = view.findViewById(R.id.btn_decrementar_item)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) = VH(
            LayoutInflater.from(parent.context).inflate(R.layout.item_carrinho, parent, false)
        )

        override fun getItemCount() = viewModel.itensVendaAtual().size

        override fun onBindViewHolder(holder: VH, position: Int) {
            val item = viewModel.itensVendaAtual()[position]
            holder.tvQtd.text = "${item.quantidade}"
            holder.tvNome.text = item.nome
            holder.tvPreco.text = PosStore.formatarValor(item.quantidade * item.precoUnitario)
            val imageValue = item.imagem
            if (imageValue.isNullOrBlank()) {
                holder.ivImagem.setImageDrawable(null)
            } else if (imageValue.startsWith("http://") || imageValue.startsWith("https://")) {
                RemoteImageLoader.load(holder.ivImagem, imageValue)
            } else {
                holder.ivImagem.setImageDrawable(null)
            }
            holder.btnIncrementar.setOnClickListener { onIncrementar(position) }
            holder.btnDecrementar.setOnClickListener { onDecrementar(position) }
        }
    }

    private fun Int.dp(): Int = (this * resources.displayMetrics.density).toInt()
}
