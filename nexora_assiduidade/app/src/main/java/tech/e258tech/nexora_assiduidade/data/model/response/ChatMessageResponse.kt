package tech.e258tech.nexora_assiduidade.data.model.response

import com.google.gson.annotations.SerializedName

/**
 * Resposta do endpoint POST /api/self-service/chat/conversas/{id}/mensagens.
 * O backend retorna {"id": <id_da_mensagem>}.
 */
data class ChatMessageResponse(
    val id: Long,
    @SerializedName("success")
    val success: Boolean? = null,
    @SerializedName("message")
    val message: String? = null
)
