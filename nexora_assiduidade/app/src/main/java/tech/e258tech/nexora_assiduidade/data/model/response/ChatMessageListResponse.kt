package tech.e258tech.nexora_assiduidade.data.model.response

import com.google.gson.annotations.SerializedName
import tech.e258tech.nexora_assiduidade.data.model.ChatMessage

/**
 * Resposta do endpoint GET /chat/conversas/{id}/mensagens.
 * O backend retorna a lista diretamente (jsonOK).
 */
typealias ChatMessageListResponse = List<BackendChatMessage>

data class BackendChatMessage(
    val id: Long,
    @SerializedName("autor_id")
    val autorId: Long?,
    @SerializedName("autor_nome")
    val autorNome: String?,
    val conteudo: String,
    val tipo: String,
    @SerializedName("ficheiro_url")
    val ficheiroUrl: String?,
    @SerializedName("created_at")
    val createdAt: String
) {
    fun toChatMessage(): ChatMessage = ChatMessage(
        id = id.toString(),
        chatId = "", // preenchido pelo fragment
        senderId = autorId?.toString() ?: "0",
        senderName = autorNome ?: "Desconhecido",
        message = conteudo,
        timestamp = createdAt,
        isRead = false,
        attachments = ficheiroUrl?.let { listOf(it) }
    )
}
