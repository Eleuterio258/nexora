package tech.e258tech.nexora_mobile.data.repository

import android.util.Log
import com.google.gson.Gson
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import okhttp3.*
import tech.e258tech.nexora_mobile.data.api.ApiConfig
import tech.e258tech.nexora_mobile.data.api.ApiService
import tech.e258tech.nexora_mobile.data.model.*
import tech.e258tech.nexora_mobile.utils.Result
import tech.e258tech.nexora_mobile.utils.safeApiCall

class ChatRepository(
    private val api: ApiService,
    private val okHttpClient: OkHttpClient
) {
    private val gson = Gson()

    // ── REST ──────────────────────────────────────────────────────────────────

    suspend fun listarConversas(): Result<List<Conversa>> =
        safeApiCall { api.listarConversas() }

    suspend fun criarConversa(tipo: String, nome: String?, participantes: List<Long>): Result<CriarConversaResponse> =
        safeApiCall { api.criarConversa(CriarConversaRequest(tipo, nome, participantes)) }

    suspend fun listarMensagens(conversaId: Long): Result<List<Mensagem>> =
        safeApiCall { api.listarMensagens(conversaId) }

    suspend fun enviarMensagem(conversaId: Long, conteudo: String): Result<Map<String, Long>> =
        safeApiCall { api.enviarMensagem(conversaId, EnviarMensagemRequest(conteudo)) }

    // ── WebSocket ─────────────────────────────────────────────────────────────

    private var webSocket: WebSocket? = null
    private val _wsEvents = Channel<WsEvent>(Channel.BUFFERED)
    val wsEvents: Flow<WsEvent> = _wsEvents.receiveAsFlow()

    sealed class WsEvent {
        data class Connected(val onlineUsers: List<Long>) : WsEvent()
        data class MessageReceived(val msg: WsMensagemRecebida) : WsEvent()
        data class UserOnline(val userId: Long) : WsEvent()
        data class UserOffline(val userId: Long) : WsEvent()
        data class TypingStarted(val userId: Long, val conversaId: Long) : WsEvent()
        data class TypingStopped(val userId: Long, val conversaId: Long) : WsEvent()
        data class Disconnected(val reason: String) : WsEvent()
        data class Error(val message: String) : WsEvent()
    }

    fun connect(token: String) {
        val url = ApiConfig.buildWsUrl(token)
        val request = Request.Builder().url(url).build()
        webSocket = okHttpClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(ws: WebSocket, response: Response) {
                Log.d("Chat", "WS connected")
            }

            override fun onMessage(ws: WebSocket, text: String) {
                try {
                    val env = gson.fromJson(text, Map::class.java)
                    val type = env["type"] as? String ?: return
                    val rawData = gson.toJson(env["data"])
                    when (type) {
                        "joined" -> {
                            val d = gson.fromJson(rawData, WsJoined::class.java)
                            _wsEvents.trySend(WsEvent.Connected(d.onlineUsers))
                        }
                        "message" -> {
                            val d = gson.fromJson(rawData, WsMensagemRecebida::class.java)
                            _wsEvents.trySend(WsEvent.MessageReceived(d))
                        }
                        "user_online"  -> {
                            val userId = (gson.fromJson(rawData, Map::class.java)["user_id"] as? Double)?.toLong() ?: return
                            _wsEvents.trySend(WsEvent.UserOnline(userId))
                        }
                        "user_offline" -> {
                            val userId = (gson.fromJson(rawData, Map::class.java)["user_id"] as? Double)?.toLong() ?: return
                            _wsEvents.trySend(WsEvent.UserOffline(userId))
                        }
                        "typing" -> {
                            val d = gson.fromJson(rawData, WsTyping::class.java)
                            _wsEvents.trySend(WsEvent.TypingStarted(d.userId, d.conversaId))
                        }
                        "stop_typing" -> {
                            val d = gson.fromJson(rawData, WsTyping::class.java)
                            _wsEvents.trySend(WsEvent.TypingStopped(d.userId, d.conversaId))
                        }
                    }
                } catch (e: Exception) {
                    Log.e("Chat", "WS parse error: ${e.message}")
                }
            }

            override fun onClosing(ws: WebSocket, code: Int, reason: String) {
                _wsEvents.trySend(WsEvent.Disconnected(reason))
            }

            override fun onFailure(ws: WebSocket, t: Throwable, response: Response?) {
                _wsEvents.trySend(WsEvent.Error(t.message ?: "Erro de ligação"))
            }
        })
    }

    fun joinRoom(conversaId: Long)  = sendWs("join",         mapOf("conversa_id" to conversaId))
    fun leaveRoom(conversaId: Long) = sendWs("leave",        mapOf("conversa_id" to conversaId))
    fun sendMessage(conversaId: Long, conteudo: String) =
        sendWs("message", mapOf("conversa_id" to conversaId, "conteudo" to conteudo))
    fun sendTyping(conversaId: Long)     = sendWs("typing",      mapOf("conversa_id" to conversaId))
    fun sendStopTyping(conversaId: Long) = sendWs("stop_typing", mapOf("conversa_id" to conversaId))

    private fun sendWs(type: String, data: Map<String, Any>) {
        val payload = mutableMapOf<String, Any>("type" to type)
        payload.putAll(data)
        webSocket?.send(gson.toJson(payload))
    }

    fun disconnect() {
        webSocket?.close(1000, "Logout")
        webSocket = null
    }
}
