package tech.e258tech.nexora_assiduidade.data.model

data class ChatMessage(
    val id: String,
    val chatId: String,
    val senderId: String,
    val senderName: String,
    val message: String,
    val timestamp: String,
    val isRead: Boolean,
    val attachments: List<String>? = null
)
