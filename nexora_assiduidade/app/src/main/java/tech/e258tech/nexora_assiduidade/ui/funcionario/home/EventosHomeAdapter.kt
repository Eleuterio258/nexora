package tech.e258tech.nexora_assiduidade.ui.funcionario.home

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.AgendaItem
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

/**
 * Faixa horizontal de eventos da semana no ecrã Home — versão compacta do
 * [tech.e258tech.nexora_assiduidade.ui.funcionario.agenda.AgendaAdapter]
 * (mesmos dados, GET /api/utilizadores/{userId}/agenda, cartões mais
 * estreitos para caberem lado a lado).
 */
class EventosHomeAdapter(
    private val items: List<AgendaItem>,
    private val onClick: (AgendaItem) -> Unit
) : RecyclerView.Adapter<EventosHomeAdapter.EventoViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): EventoViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_evento_home, parent, false)
        return EventoViewHolder(view)
    }

    override fun onBindViewHolder(holder: EventoViewHolder, position: Int) {
        holder.bind(items[position], onClick)
    }

    override fun getItemCount(): Int = items.size

    class EventoViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val viewAccent: View = itemView.findViewById(R.id.viewEventoHomeAccent)
        private val viewDot: View = itemView.findViewById(R.id.viewEventoHomeDot)
        private val tvData: TextView = itemView.findViewById(R.id.tvEventoHomeData)
        private val tvHoraInicio: TextView = itemView.findViewById(R.id.tvEventoHomeHoraInicio)
        private val tvHoraFim: TextView = itemView.findViewById(R.id.tvEventoHomeHoraFim)
        private val tvTitulo: TextView = itemView.findViewById(R.id.tvEventoHomeTitulo)
        private val tvDescricao: TextView = itemView.findViewById(R.id.tvEventoHomeDescricao)

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
                tvHoraFim.text = "- ${item.hora_fim}"
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
