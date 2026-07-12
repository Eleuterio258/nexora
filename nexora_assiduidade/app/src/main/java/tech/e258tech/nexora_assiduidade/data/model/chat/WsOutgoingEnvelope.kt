package tech.e258tech.nexora_assiduidade.data.model.chat

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * Envelope JSON recebido do servidor WebSocket.
 * Formato: {"type": "message", "data": {...}}
 */
data class WsOutgoingEnvelope<T>(
    val type: String,
    val data: T
) {
    companion object {
        @JvmStatic
        val gson = Gson()

        inline fun <reified T> fromJson(json: String): WsOutgoingEnvelope<T>? {
            return try {
                val type = object : TypeToken<WsOutgoingEnvelope<T>>() {}.type
                gson.fromJson(json, type)
            } catch (e: Exception) {
                null
            }
        }
    }
}
