package tech.e258tech.nexora_assiduidade.ui.funcionario.chat.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.chat.Conversation

/**
 * Adapter para lista de conversas de chat.
 */
class ConversationAdapter(
    private val onItemClick: (Conversation) -> Unit
) : ListAdapter<Conversation, ConversationAdapter.ConversationViewHolder>(DiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ConversationViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_conversation, parent, false)
        return ConversationViewHolder(view)
    }

    override fun onBindViewHolder(holder: ConversationViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class ConversationViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvName: TextView = itemView.findViewById(R.id.tvConversationName)
        private val tvLastMessage: TextView = itemView.findViewById(R.id.tvLastMessage)
        private val tvTime: TextView = itemView.findViewById(R.id.tvConversationTime)
        private val tvUnread: TextView = itemView.findViewById(R.id.tvUnreadCount)
        private val tvType: TextView = itemView.findViewById(R.id.tvConversationType)

        fun bind(conversation: Conversation) {
            tvName.text = conversation.displayName()
            tvLastMessage.text = conversation.ultima_mensagem ?: "Sem mensagens"
            tvTime.text = conversation.ultima_data ?: ""
            tvType.text = if (conversation.tipo == "individual") "Privado" else "Grupo"

            if (conversation.nao_lidas > 0) {
                tvUnread.visibility = View.VISIBLE
                tvUnread.text = conversation.nao_lidas.toString()
            } else {
                tvUnread.visibility = View.GONE
            }

            itemView.setOnClickListener { onItemClick(conversation) }
        }
    }

    private class DiffCallback : DiffUtil.ItemCallback<Conversation>() {
        override fun areItemsTheSame(oldItem: Conversation, newItem: Conversation): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: Conversation, newItem: Conversation): Boolean {
            return oldItem == newItem
        }
    }
}
