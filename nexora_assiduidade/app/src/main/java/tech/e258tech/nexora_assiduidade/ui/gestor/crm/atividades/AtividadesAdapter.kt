package tech.e258tech.nexora_assiduidade.ui.gestor.crm.atividades

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Atividade
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

/**
 * Partilhado pelas 3 utilizações: lista global de Atividades, e as secções
 * embutidas nos detalhes de Lead e de Oportunidade.
 */
class AtividadesAdapter(
    private val items: List<Atividade>,
    private val onClick: ((Atividade) -> Unit)?,
    private val onConcluir: ((Atividade) -> Unit)?,
    private val podeConcluir: Boolean = true,
) : RecyclerView.Adapter<AtividadesAdapter.AtividadeViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): AtividadeViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_atividade, parent, false)
        return AtividadeViewHolder(view)
    }

    override fun onBindViewHolder(holder: AtividadeViewHolder, position: Int) {
        holder.bind(items[position], onClick, onConcluir, podeConcluir)
    }

    override fun getItemCount(): Int = items.size

    class AtividadeViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvTitulo: TextView = itemView.findViewById(R.id.tvAtividadeTitulo)
        private val tvTipo: TextView = itemView.findViewById(R.id.tvAtividadeTipo)
        private val tvData: TextView = itemView.findViewById(R.id.tvAtividadeData)
        private val btnConcluir: Button = itemView.findViewById(R.id.btnConcluir)

        fun bind(
            item: Atividade,
            onClick: ((Atividade) -> Unit)?,
            onConcluir: ((Atividade) -> Unit)?,
            podeConcluir: Boolean
        ) {
            tvTitulo.text = item.titulo
            tvTipo.text = Atividade.tipoLabel(item.tipo) + if (item.concluida) " · Concluída" else ""
            tvData.text = item.data_atividade?.let { DateTimeUtils.formatDateTime(it) } ?: "Sem data"

            btnConcluir.visibility = if (!item.concluida && podeConcluir && onConcluir != null) View.VISIBLE else View.GONE
            btnConcluir.setOnClickListener { onConcluir?.invoke(item) }

            if (onClick != null) {
                itemView.setOnClickListener { onClick(item) }
            } else {
                itemView.setOnClickListener(null)
                itemView.isClickable = false
            }
        }
    }
}
