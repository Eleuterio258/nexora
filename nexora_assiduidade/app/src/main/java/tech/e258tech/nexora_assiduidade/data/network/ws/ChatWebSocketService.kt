package tech.e258tech.nexora_assiduidade.data.network.ws

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.data.model.chat.PendingMessage
import tech.e258tech.nexora_assiduidade.data.model.chat.WsIncomingMessage
import tech.e258tech.nexora_assiduidade.data.model.chat.WsMessagePayload
import tech.e258tech.nexora_assiduidade.data.model.chat.WsOutgoingEnvelope
import tech.e258tech.nexora_assiduidade.data.model.chat.WsTypingPayload
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Serviço singleton de WebSocket nativo para o chat do ERP.
 * Inclui fila de mensagens pendentes, reconexão automática com backoff
 * exponencial e heartbeat para detectar ligações mortas.
 */
object ChatWebSocketService {

    private const val TAG = "ChatWebSocket"

    // Backoff exponencial: 1s, 2s, 4s, 8s, ... até 30s
    private const val RECONNECT_DELAY_INITIAL_MS = 1000L
    private const val RECONNECT_DELAY_MAX_MS = 30000L
    private const val HEARTBEAT_INTERVAL_SECONDS = 20L

    private var webSocket: WebSocket? = null
    private var isManuallyClosed = false
    @Volatile
    private var isOpen = false
    private var reconnectAttempt = 0

    private val gson = Gson()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mainHandler = Handler(Looper.getMainLooper())

    private val pendingMessages = CopyOnWriteArrayList<PendingMessage>()

    private var onMessageReceived: ((WsMessagePayload) -> Unit)? = null
    private var onMessageDelivered: ((String, Long) -> Unit)? = null
    private var onTyping: ((WsTypingPayload) -> Unit)? = null
    private var onStopTyping: ((WsTypingPayload) -> Unit)? = null
    private var onConnected: (() -> Unit)? = null
    private var onDisconnected: (() -> Unit)? = null
    private var onError: ((Throwable) -> Unit)? = null

    private val reconnecting = AtomicBoolean(false)

    val isConnected: Boolean
        get() = webSocket != null && isOpen && !isManuallyClosed

    private val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(0, TimeUnit.SECONDS) // necessário para WebSocket
            .writeTimeout(10, TimeUnit.SECONDS)
            .pingInterval(HEARTBEAT_INTERVAL_SECONDS, TimeUnit.SECONDS)
            .build()
    }

    /**
     * Abre a ligação WebSocket usando o token da sessão atual.
     * Se falhar, inicia reconexão automática.
     */
    fun connect(context: Context) {
        if (webSocket != null) {
            Log.d(TAG, "WebSocket já inicializado")
            return
        }

        val sessionManager = SessionManager(context)
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Log.w(TAG, "Token em falta; não é possível conectar WebSocket")
            scheduleReconnect(context)
            return
        }

        isManuallyClosed = false
        val httpUrl = BuildConfig.ERP_BASE_URL.trimEnd('/')
        val wsUrl = httpUrl.replaceFirst(Regex("^http"), "ws") + Constants.WS_CHAT_PATH + "?token=$token"

        val request = Request.Builder().url(wsUrl).build()
        webSocket = client.newWebSocket(request, ChatWebSocketListener(context))
    }

    /**
     * Fecha a ligação WebSocket e cancela reconexões.
     */
    fun disconnect() {
        isManuallyClosed = true
        isOpen = false
        reconnecting.set(false)
        pendingMessages.clear()
        webSocket?.close(1000, "Utilizador saiu")
        webSocket = null
    }

    /**
     * Entra numa sala de conversa.
     */
    fun joinChat(conversaId: Long) {
        send(WsIncomingMessage(type = Constants.WS_ACTION_JOIN, conversaId = conversaId))
    }

    /**
     * Sai de uma sala de conversa.
     */
    fun leaveChat(conversaId: Long) {
        send(WsIncomingMessage(type = Constants.WS_ACTION_LEAVE, conversaId = conversaId))
    }

    /**
     * Envia uma mensagem de texto para uma conversa.
     * Se não houver ligação, coloca na fila de pendentes.
     */
    fun sendMessage(conversaId: Long, conteudo: String, tipoMensagem: String = "texto"): String {
        val clientId = "${System.currentTimeMillis()}_${conversaId}_${conteudo.hashCode()}"
        val pending = PendingMessage(clientId, conversaId, conteudo, tipoMensagem)

        if (isConnected) {
            emit(pending)
        } else {
            pendingMessages.add(pending)
            Log.d(TAG, "Mensagem guardada como pendente: $clientId")
        }
        return clientId
    }

    /**
     * Notifica que o utilizador começou a digitar.
     */
    fun sendTyping(conversaId: Long) {
        send(WsIncomingMessage(type = Constants.WS_ACTION_TYPING, conversaId = conversaId))
    }

    /**
     * Notifica que o utilizador parou de digitar.
     */
    fun sendStopTyping(conversaId: Long) {
        send(WsIncomingMessage(type = Constants.WS_ACTION_STOP_TYPING, conversaId = conversaId))
    }

    /**
     * Marca uma notificação como lida.
     */
    fun markRead(notifId: Long) {
        send(WsIncomingMessage(type = Constants.WS_ACTION_MARK_READ, notifId = notifId))
    }

    /**
     * Marca todas as notificações como lidas.
     */
    fun markAllRead() {
        send(WsIncomingMessage(type = Constants.WS_ACTION_MARK_ALL_READ))
    }

    // region Callbacks
    fun setOnMessageReceived(callback: (WsMessagePayload) -> Unit) {
        onMessageReceived = callback
    }

    /**
     * Chamado quando o servidor confirma/difunde uma mensagem enviada.
     * Parâmetros: clientId, messageId (id gerado pelo servidor).
     */
    fun setOnMessageDelivered(callback: (clientId: String, serverMessageId: Long) -> Unit) {
        onMessageDelivered = callback
    }

    fun setOnTyping(callback: (WsTypingPayload) -> Unit) {
        onTyping = callback
    }

    fun setOnStopTyping(callback: (WsTypingPayload) -> Unit) {
        onStopTyping = callback
    }

    fun setOnConnected(callback: () -> Unit) {
        onConnected = callback
    }

    fun setOnDisconnected(callback: () -> Unit) {
        onDisconnected = callback
    }

    fun setOnError(callback: (Throwable) -> Unit) {
        onError = callback
    }
    // endregion

    private fun emit(pending: PendingMessage) {
        val message = WsIncomingMessage(
            type = Constants.WS_ACTION_MESSAGE,
            conversaId = pending.conversaId,
            conteudo = pending.conteudo,
            tipoMensagem = pending.tipoMensagem,
            clientId = pending.clientId
        )
        send(message)
    }

    private fun send(message: WsIncomingMessage) {
        val json = gson.toJson(message)
        val sent = webSocket?.send(json) ?: false
        if (!sent) {
            Log.w(TAG, "Não foi possível enviar; adicionado à fila: $json")
            if (message.type == Constants.WS_ACTION_MESSAGE && !message.clientId.isNullOrBlank()) {
                pendingMessages.add(
                    PendingMessage(
                        clientId = message.clientId,
                        conversaId = message.conversaId ?: 0,
                        conteudo = message.conteudo ?: "",
                        tipoMensagem = message.tipoMensagem ?: "texto"
                    )
                )
            }
        }
    }

    private fun retryPendingMessages() {
        if (pendingMessages.isEmpty()) return
        Log.d(TAG, "A reenviar ${pendingMessages.size} mensagens pendentes")
        val copy = pendingMessages.toList()
        pendingMessages.clear()
        copy.forEach { emit(it) }
    }

    private fun scheduleReconnect(context: Context) {
        if (isManuallyClosed || reconnecting.getAndSet(true)) return

        val delay = (RECONNECT_DELAY_INITIAL_MS * (1 shl reconnectAttempt.coerceAtMost(5)))
            .coerceAtMost(RECONNECT_DELAY_MAX_MS)
        reconnectAttempt++

        Log.d(TAG, "Reconexão agendada dentro de ${delay}ms (tentativa $reconnectAttempt)")
        serviceScope.launch {
            delay(delay)
            if (!isManuallyClosed && webSocket == null) {
                reconnecting.set(false)
                mainHandler.post { connect(context) }
            } else {
                reconnecting.set(false)
            }
        }
    }

    private fun handleIncoming(text: String) {
        try {
            val base = gson.fromJson(text, Map::class.java) ?: return
            val type = base["type"] as? String ?: return

            when (type) {
                Constants.WS_EVENT_MESSAGE -> {
                    val envelope = gson.fromJson(text, WsOutgoingEnvelope::class.java)
                    val payloadJson = gson.toJson(envelope.data)
                    val payload = gson.fromJson(payloadJson, WsMessagePayload::class.java)

                    // Se for uma mensagem que nós enviamos, trata como ACK/delivery.
                    payload.clientId?.let { clientId ->
                        mainHandler.post { onMessageDelivered?.invoke(clientId, payload.id) }
                    }

                    mainHandler.post { onMessageReceived?.invoke(payload) }
                }
                Constants.WS_EVENT_MESSAGE_ACK -> {
                    val envelope = gson.fromJson(text, WsOutgoingEnvelope::class.java)
                    val data = envelope.data as? Map<*, *> ?: return
                    val clientId = data["client_id"] as? String ?: return
                    val id = (data["id"] as? Number)?.toLong() ?: return
                    mainHandler.post { onMessageDelivered?.invoke(clientId, id) }
                }
                Constants.WS_EVENT_TYPING -> {
                    val payload = parseTypingPayload(text)
                    payload?.let { mainHandler.post { onTyping?.invoke(it) } }
                }
                Constants.WS_EVENT_STOP_TYPING -> {
                    val payload = parseTypingPayload(text)
                    payload?.let { mainHandler.post { onStopTyping?.invoke(it) } }
                }
                Constants.WS_EVENT_ERROR -> {
                    val msg = base["data"] as? String ?: "Erro desconhecido no WebSocket"
                    mainHandler.post { onError?.invoke(Exception(msg)) }
                }
                else -> Log.d(TAG, "Evento ignorado: $type")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao processar mensagem WebSocket", e)
        }
    }

    private fun parseTypingPayload(json: String): WsTypingPayload? {
        return try {
            val envelope = gson.fromJson(json, WsOutgoingEnvelope::class.java)
            gson.fromJson(gson.toJson(envelope.data), WsTypingPayload::class.java)
        } catch (e: Exception) {
            null
        }
    }

    private class ChatWebSocketListener(
        private val context: Context
    ) : WebSocketListener() {
        override fun onOpen(webSocket: WebSocket, response: Response) {
            Log.d(TAG, "WebSocket aberto")
            isOpen = true
            reconnectAttempt = 0
            mainHandler.post { onConnected?.invoke() }
            retryPendingMessages()
        }

        override fun onMessage(webSocket: WebSocket, text: String) {
            handleIncoming(text)
        }

        override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
            Log.d(TAG, "WebSocket a fechar: $code / $reason")
            webSocket.close(code, reason)
        }

        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
            Log.d(TAG, "WebSocket fechado: $code / $reason")
            isOpen = false
            this@ChatWebSocketService.webSocket = null
            mainHandler.post { onDisconnected?.invoke() }
            if (!isManuallyClosed) {
                scheduleReconnect(context)
            }
        }

        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            Log.e(TAG, "WebSocket falhou", t)
            isOpen = false
            this@ChatWebSocketService.webSocket = null
            mainHandler.post { onError?.invoke(t) }
            if (!isManuallyClosed) {
                scheduleReconnect(context)
            }
        }
    }
}
