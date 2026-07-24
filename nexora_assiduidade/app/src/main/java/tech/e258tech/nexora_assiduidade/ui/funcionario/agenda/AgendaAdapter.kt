package tech.e258tech.nexora_assiduidade.ui.funcionario.agenda

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.AgendaItem
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

class AgendaAdapter(
    private val items: List<AgendaItem>,
    private val onClick: (AgendaItem) -> Unit
) : RecyclerView.Adapter<AgendaAdapter.AgendaViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): AgendaViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_agenda_evento, parent, false)
        return AgendaViewHolder(view)
    }

    override fun onBindViewHolder(holder: AgendaViewHolder, position: Int) {
        holder.bind(items[position], onClick)
    }

    override fun getItemCount(): Int = items.size

    class AgendaViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val viewAccent: View = itemView.findViewById(R.id.viewAgendaAccent)
        private val viewDot: View = itemView.findViewById(R.id.viewAgendaDot)
        private val tvData: TextView = itemView.findViewById(R.id.tvAgendaData)
        private val tvHoraInicio: TextView = itemView.findViewById(R.id.tvAgendaHoraInicio)
        private val tvHoraFim: TextView = itemView.findViewById(R.id.tvAgendaHoraFim)
        private val tvTitulo: TextView = itemView.findViewById(R.id.tvAgendaTitulo)
        private val tvDescricao: TextView = itemView.findViewById(R.id.tvAgendaDescricao)

        fun bind(item: AgendaItem, onClick: (AgendaItem) -> Unit) {
            val cor = corPorTipo(item.tipo)
            viewAccent.setBackgroundColor(cor)
            viewDot.backgroundTintList = android.content.res.ColorStateList.valueOf(cor)

            tvData.text = DateTimeUtils.formatDate(item.data)
            tvHoraInicio.text = item.hora_inicio
            if (item.hora_fim.isNullOrBlank()) {
                tvHoraFim.visibility = View.GONE
            } else {
                tvHoraFim.visibility = View.VISIBLE
                tvHoraFim.text = item.hora_fim
            }

            tvTitulo.text = item.titulo
            if (item.descricao.isNullOrBlank()) {
                tvDescricao.visibility = View.GONE
            } else {
                tvDescricao.visibility = View.VISIBLE
                tvDescricao.text = item.descricao
            }

            itemView.setOnClickListener { onClick(item) }
        }

        private fun corPorTipo(tipo: String): Int {
            val context = itemView.context
            val colorRes = when (tipo) {
                "workshop" -> R.color.blue
                "outro" -> R.color.amber
                else -> R.color.green
            }
            return context.getColor(colorRes)
        }
    }
}
