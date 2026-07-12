package tech.e258tech.nexora_assiduidade.data.model.chat

/**
 * Mensagem pendente de envio via WebSocket.
 * Guardada em memória enquanto a ligação não estiver disponível.
 */
data class PendingMessage(
    val clientId: String,
    val conversaId: Long,
    val conteudo: String,
    val tipoMensagem: String = "texto"
)
