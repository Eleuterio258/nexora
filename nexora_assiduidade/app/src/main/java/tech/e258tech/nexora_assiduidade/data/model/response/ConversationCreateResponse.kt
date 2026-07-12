package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta do endpoint POST /chat/conversas.
 * O backend retorna {"id": <id_da_conversa>}.
 */
data class ConversationCreateResponse(
    val id: Long
)
