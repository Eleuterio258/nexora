package tech.e258tech.nexora_assiduidade.ui.funcionario.notifications

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Notification
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

class NotificationAdapter(
    private val items: List<Notification>,
    private val onClick: (Notification) -> Unit
) : RecyclerView.Adapter<NotificationAdapter.NotificationViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): NotificationViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_notification, parent, false)
        return NotificationViewHolder(view)
    }

    override fun onBindViewHolder(holder: NotificationViewHolder, position: Int) {
        holder.bind(items[position], onClick)
    }

    override fun getItemCount(): Int = items.size

    class NotificationViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvTitulo: TextView = itemView.findViewById(R.id.tvNotificationTitulo)
        private val tvMensagem: TextView = itemView.findViewById(R.id.tvNotificationMensagem)
        private val tvData: TextView = itemView.findViewById(R.id.tvNotificationData)

        fun bind(item: Notification, onClick: (Notification) -> Unit) {
            tvTitulo.text = item.titulo
            tvTitulo.alpha = if (item.lida) 0.6f else 1f
            tvMensagem.text = item.mensagem
            tvData.text = DateTimeUtils.formatDateTime(item.created_at)
            itemView.setOnClickListener { onClick(item) }
        }
    }
}
