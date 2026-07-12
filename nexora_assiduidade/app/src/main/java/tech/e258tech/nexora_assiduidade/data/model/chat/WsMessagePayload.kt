package tech.e258tech.nexora_assiduidade.data.model.chat

import com.google.gson.annotations.SerializedName
import tech.e258tech.nexora_assiduidade.data.model.ChatMessage

/**
 * Payload do evento "message" recebido via WebSocket.
 */
data class WsMessagePayload(
    val id: Long,
    @SerializedName("conversa_id")
    val conversaId: Long,
    @SerializedName("autor_id")
    val autorId: Long,
    @SerializedName("autor_nome")
    val autorNome: String?,
    val conteudo: String,
    val tipo: String,
    @SerializedName("created_at")
    val createdAt: String,
    val minha: Boolean = false,
    @SerializedName("client_id")
    val clientId: String? = null
) {
    fun toChatMessage(currentUserId: Long): ChatMessage = ChatMessage(
        id = id.toString(),
        chatId = conversaId.toString(),
        senderId = autorId.toString(),
        senderName = autorNome ?: "Desconhecido",
        message = conteudo,
        timestamp = createdAt,
        isRead = minha,
        attachments = null
    )
}
