package tech.e258tech.nexora_assiduidade.data.model.chat

import com.google.gson.annotations.SerializedName

/**
 * Payload dos eventos "typing" / "stop_typing" recebidos via WebSocket.
 */
data class WsTypingPayload(
    @SerializedName("user_id")
    val userId: Long,
    @SerializedName("conversa_id")
    val conversaId: Long
)
