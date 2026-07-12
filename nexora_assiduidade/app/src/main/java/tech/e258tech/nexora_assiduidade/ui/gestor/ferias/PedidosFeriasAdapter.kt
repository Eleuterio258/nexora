package tech.e258tech.nexora_assiduidade.ui.gestor.ferias

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Ausencia

class PedidosFeriasAdapter(
    private val items: MutableList<Ausencia>,
    private val onAprovar: (Ausencia) -> Unit,
    private val onRejeitar: (Ausencia) -> Unit,
) : RecyclerView.Adapter<PedidosFeriasAdapter.PedidoViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PedidoViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_pedido_ferias, parent, false)
        return PedidoViewHolder(view)
    }

    override fun onBindViewHolder(holder: PedidoViewHolder, position: Int) {
        holder.bind(items[position], onAprovar, onRejeitar)
    }

    override fun getItemCount(): Int = items.size

    fun removeItem(item: Ausencia) {
        val index = items.indexOf(item)
        if (index >= 0) {
            items.removeAt(index)
            notifyItemRemoved(index)
        }
    }

    class PedidoViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvFuncionario: TextView = itemView.findViewById(R.id.tvPedidoFuncionario)
        private val tvTipo: TextView = itemView.findViewById(R.id.tvPedidoTipo)
        private val tvDatas: TextView = itemView.findViewById(R.id.tvPedidoDatas)
        private val tvEstado: TextView = itemView.findViewById(R.id.tvPedidoEstado)
        private val layoutAcoes: View = itemView.findViewById(R.id.layoutPedidoAcoes)
        private val btnAprovar: Button = itemView.findViewById(R.id.btnAprovar)
        private val btnRejeitar: Button = itemView.findViewById(R.id.btnRejeitar)

        fun bind(item: Ausencia, onAprovar: (Ausencia) -> Unit, onRejeitar: (Ausencia) -> Unit) {
            tvFuncionario.text = item.funcionario_nome ?: "Funcionário #${item.funcionario_id}"
            tvTipo.text = item.tipo_nome ?: "Ausência"
            tvDatas.text = "${item.data_inicio} a ${item.data_fim}" + (item.dias?.let { " ($it dias)" } ?: "")
            tvEstado.text = when (item.estado) {
                "pendente" -> "Pendente"
                "aprovado" -> "Aprovado"
                "rejeitado" -> "Rejeitado"
                else -> item.estado
            }

            val pendente = item.estado == "pendente"
            layoutAcoes.visibility = if (pendente) View.VISIBLE else View.GONE
            btnAprovar.setOnClickListener { onAprovar(item) }
            btnRejeitar.setOnClickListener { onRejeitar(item) }
        }
    }
}
