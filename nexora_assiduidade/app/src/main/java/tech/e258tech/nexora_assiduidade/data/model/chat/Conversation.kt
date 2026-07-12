package tech.e258tech.nexora_assiduidade.data.model.chat

/**
 * Representa uma conversa retornada pelo endpoint /chat/conversas.
 */
data class Conversation(
    val id: Long,
    val nome: String?,
    val tipo: String,
    val ultima_mensagem: String?,
    val ultima_data: String?,
    val nao_lidas: Int = 0,
    val participantes: List<ConversationParticipant>? = null
) {
    fun displayName(): String = nome ?: "Conversa ${id}"
}
