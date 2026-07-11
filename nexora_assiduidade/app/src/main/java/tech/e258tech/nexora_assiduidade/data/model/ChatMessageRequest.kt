package tech.e258tech.nexora_assiduidade.data.model

data class ChatMessageRequest(
    val chatId: String,
    val message: String,
    val attachments: List<String>? = null
)
