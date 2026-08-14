package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.button.MaterialButton
import tech.e258tech.paycore.repository.Pedido
import tech.e258tech.paycore.repository.SaleRepository

class PedidosActivity : AppCompatActivity() {

    private lateinit var rvPedidos: RecyclerView
    private lateinit var tvVazio: TextView
    private lateinit var tvCount: TextView
    private lateinit var adapter: PedidoAdapter

    override fun onResume() {
        super.onResume()
        atualizarLista()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_pedidos)

        rvPedidos = findViewById(R.id.rv_pedidos)
        tvVazio   = findViewById(R.id.tv_pedidos_vazio)
        tvCount   = findViewById(R.id.tv_pedidos_count)

        adapter = PedidoAdapter(
            onRetomar = { pedido ->
                SaleRepository.retomarPedido(pedido.id)
                startActivity(Intent(this, NovaVendaActivity::class.java))
                finish()
            },
            onCancelar = { pedido ->
                SaleRepository.cancelarPedido(pedido.id)
                atualizarLista()
            }
        )
        rvPedidos.adapter = adapter

        findViewById<MaterialButton>(R.id.btn_novo_pedido).setOnClickListener {
            startActivity(Intent(this, NovaVendaActivity::class.java))
            finish()
        }
    }

    private fun atualizarLista() {
        val lista = SaleRepository.pedidosAtivos()
        adapter.atualizar(lista)
        val n = lista.size
        tvCount.text = "$n ${if (n == 1) "pedido activo" else "pedidos activos"}"
        tvVazio.visibility   = if (lista.isEmpty()) View.VISIBLE else View.GONE
        rvPedidos.visibility = if (lista.isEmpty()) View.GONE   else View.VISIBLE
    }

    private inner class PedidoAdapter(
        private val onRetomar: (Pedido) -> Unit,
        private val onCancelar: (Pedido) -> Unit
    ) : RecyclerView.Adapter<PedidoAdapter.VH>() {

        private val itens = mutableListOf<Pedido>()

        inner class VH(view: View) : RecyclerView.ViewHolder(view) {
            val tvNumero    : TextView      = view.findViewById(R.id.tv_pedido_numero)
            val tvNota      : TextView      = view.findViewById(R.id.tv_pedido_nota)
            val tvHora      : TextView      = view.findViewById(R.id.tv_pedido_hora)
            val tvTotal     : TextView      = view.findViewById(R.id.tv_pedido_total)
            val tvItensCount: TextView      = view.findViewById(R.id.tv_pedido_itens_count)
            val tvItens     : TextView      = view.findViewById(R.id.tv_pedido_itens)
            val btnRetomar  : MaterialButton = view.findViewById(R.id.btn_retomar_pedido)
            val btnCancelar : MaterialButton = view.findViewById(R.id.btn_cancelar_pedido)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int) = VH(
            LayoutInflater.from(parent.context).inflate(R.layout.item_pedido, parent, false)
        )

        override fun getItemCount() = itens.size

        fun atualizar(novos: List<Pedido>) {
            itens.clear()
            itens.addAll(novos)
            notifyDataSetChanged()
        }

        override fun onBindViewHolder(holder: VH, position: Int) {
            val pedido = itens[position]
            val totalItens = pedido.itens.sumOf { it.quantidade }

            holder.tvNumero.text     = "Pedido #${pedido.numero}"
            holder.tvNota.text       = pedido.nota.ifBlank { "" }
            holder.tvNota.visibility = if (pedido.nota.isBlank()) View.GONE else View.VISIBLE
            holder.tvHora.text       = PosStore.formatarDataHora(pedido.dataHora)
            holder.tvTotal.text      = PosStore.formatarValor(pedido.total)
            holder.tvItensCount.text = "$totalItens ${if (totalItens == 1) "item" else "itens"}"
            holder.tvItens.text      = pedido.itens.joinToString("\n") {
                "${it.quantidade}x ${it.nome}  ${PosStore.formatarValor(it.quantidade * it.precoUnitario)}"
            }

            holder.btnRetomar.setOnClickListener  { onRetomar(pedido) }
            holder.btnCancelar.setOnClickListener { onCancelar(pedido) }
        }
    }
}
