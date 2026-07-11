package tech.e258tech.nexora_assiduidade.ui.funcionario.history

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.response.ClockRecordResponse
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

class HistoryAdapter(
    private val items: List<ClockRecordResponse>
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
        private val tvEvent: TextView = itemView.findViewById(R.id.tvEventType)
        private val tvDateTime: TextView = itemView.findViewById(R.id.tvRecordDateTime)
        private val tvSource: TextView = itemView.findViewById(R.id.tvRecordSource)
        private val tvSync: TextView = itemView.findViewById(R.id.tvRecordSyncStatus)

        fun bind(item: ClockRecordResponse) {
            tvEvent.text = when (item.event_type) {
                "ENTRY" -> "Entrada"
                "EXIT" -> "Saida"
                "BREAK_START" -> "Inicio de pausa"
                "BREAK_END" -> "Fim de pausa"
                else -> item.event_type
            }
            tvDateTime.text = DateTimeUtils.formatDateTime(item.recorded_at)
            tvSource.text = "Origem: ${item.source}"
            tvSync.text = "Sync: ${item.sync_status}"
        }
    }
}
