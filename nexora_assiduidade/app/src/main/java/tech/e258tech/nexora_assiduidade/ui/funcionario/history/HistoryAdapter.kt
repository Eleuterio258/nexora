package tech.e258tech.nexora_assiduidade.ui.funcionario.history

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.response.PresencaResponse
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

class HistoryAdapter(
    private val items: List<PresencaResponse>
) : RecyclerView.Adapter<HistoryAdapter.HistoryViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): HistoryViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_history_record, parent, false)
        return HistoryViewHolder(view)
    }

    override fun onBindViewHolder(holder: HistoryViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    class HistoryViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvTipo: TextView = itemView.findViewById(R.id.tvEventType)
        private val tvHoras: TextView = itemView.findViewById(R.id.tvRecordDateTime)
        private val tvTrabalhadas: TextView = itemView.findViewById(R.id.tvRecordSource)
        private val tvObservacao: TextView = itemView.findViewById(R.id.tvRecordSyncStatus)

        fun bind(item: PresencaResponse) {
            tvTipo.text = when (item.tipo) {
                "atraso" -> "Atraso"
                "falta" -> "Falta"
                else -> "Presente"
            }
            val data = DateTimeUtils.formatDate(item.data)
            val entrada = item.hora_entrada ?: "--:--"
            val saida = item.hora_saida ?: "--:--"
            tvHoras.text = "$data — entrada $entrada, saida $saida"

            tvTrabalhadas.text = item.horas_trabalhadas?.let { "Horas trabalhadas: %.1f".format(it) }
                ?: "Horas trabalhadas: —"

            tvObservacao.text = item.observacao.orEmpty()
            tvObservacao.visibility = if (item.observacao.isNullOrBlank()) View.GONE else View.VISIBLE
        }
    }
}
