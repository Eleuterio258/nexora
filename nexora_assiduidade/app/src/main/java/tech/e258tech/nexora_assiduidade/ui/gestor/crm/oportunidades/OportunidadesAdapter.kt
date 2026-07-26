package tech.e258tech.nexora_assiduidade.ui.gestor.crm.oportunidades

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Oportunidade

class OportunidadesAdapter(
    private val items: List<Oportunidade>,
    private val onClick: (Oportunidade) -> Unit,
) : RecyclerView.Adapter<OportunidadesAdapter.OportunidadeViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): OportunidadeViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_oportunidade, parent, false)
        return OportunidadeViewHolder(view)
    }

    override fun onBindViewHolder(holder: OportunidadeViewHolder, position: Int) {
        holder.bind(items[position], onClick)
    }

    override fun getItemCount(): Int = items.size

    class OportunidadeViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvTitulo: TextView = itemView.findViewById(R.id.tvOportunidadeTitulo)
        private val tvEstagio: TextView = itemView.findViewById(R.id.tvOportunidadeEstagio)
        private val tvValor: TextView = itemView.findViewById(R.id.tvOportunidadeValor)
        private val tvProbabilidade: TextView = itemView.findViewById(R.id.tvOportunidadeProbabilidade)

        fun bind(item: Oportunidade, onClick: (Oportunidade) -> Unit) {
            tvTitulo.text = item.titulo
            tvEstagio.text = "Estágio: ${Oportunidade.estagioLabel(item.estagio)}"
            tvValor.text = "Valor: ${item.moeda} ${"%.2f".format(item.valor_estimado)}"
            tvProbabilidade.text = "Probabilidade: ${item.probabilidade}%"
            itemView.setOnClickListener { onClick(item) }
        }
    }
}
