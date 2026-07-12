package tech.e258tech.nexora_assiduidade.data.model.chat

import com.google.gson.annotations.SerializedName

/**
 * Mensagem enviada pelo cliente Android para o servidor WebSocket.
 */
data class WsIncomingMessage(
    val type: String,
    @SerializedName("conversa_id")
    val conversaId: Long? = null,
    val conteudo: String? = null,
    @SerializedName("tipo_mensagem")
    val tipoMensagem: String? = null,
    @SerializedName("notif_id")
    val notifId: Long? = null,
    @SerializedName("client_id")
    val clientId: String? = null
)
