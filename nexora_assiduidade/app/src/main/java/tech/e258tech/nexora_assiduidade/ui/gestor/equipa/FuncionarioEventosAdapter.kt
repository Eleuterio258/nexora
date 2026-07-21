package tech.e258tech.nexora_assiduidade.ui.gestor.equipa

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.response.EventoAssiduidadeResponse
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

/**
 * Lista de eventos de assiduidade (modelo novo) de um funcionário, no ecrã
 * de detalhe do gestor. Reaproveita o layout item_history_record.xml já
 * usado por HistoryAdapter (self-service), só muda a fonte de dados.
 */
class FuncionarioEventosAdapter(
    private val items: List<EventoAssiduidadeResponse>
) : RecyclerView.Adapter<FuncionarioEventosAdapter.EventoViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): EventoViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_history_record, parent, false)
        return EventoViewHolder(view)
    }

    override fun onBindViewHolder(holder: EventoViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    class EventoViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvTipo: TextView = itemView.findViewById(R.id.tvEventType)
        private val tvQuando: TextView = itemView.findViewById(R.id.tvRecordDateTime)
        private val tvOrigem: TextView = itemView.findViewById(R.id.tvRecordSource)
        private val tvNota: TextView = itemView.findViewById(R.id.tvRecordSyncStatus)

        fun bind(item: EventoAssiduidadeResponse) {
            tvTipo.text = item.tipo_evento_nome
            tvQuando.text = DateTimeUtils.formatDateTime(item.ocorrido_em)

            val origemLabel = when (item.origem) {
                "biometria" -> "Biometria"
                "manual" -> "Manual"
                "importacao" -> "Importação"
                "api" -> "API"
                else -> item.origem.replaceFirstChar { it.uppercase() }
            }
            tvOrigem.text = if (item.estado == "valido") {
                origemLabel
            } else {
                "$origemLabel · ${item.estado}"
            }

            val nota = item.motivo ?: item.observacoes
            tvNota.text = nota.orEmpty()
            tvNota.visibility = if (nota.isNullOrBlank()) View.GONE else View.VISIBLE
        }
    }
}
