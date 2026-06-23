package tech.e258tech.nexora_mobile.data.model

import com.google.gson.annotations.SerializedName

data class Conversa(
    val id: Long,
    val nome: String?,
    val tipo: String,                         // individual | grupo
    @SerializedName("ultima_mensagem") val ultimaMensagem: String?,
    @SerializedName("ultima_data")     val ultimaData: String?,
    @SerializedName("nao_lidas")       val naoLidas: Int
)

data class ListaConversasResponse(
    val ok: Boolean,
    val conversas: List<Conversa>
)

data class Mensagem(
    val id: Long,
    @SerializedName("autor_id")   val autorId: Long?,
    @SerializedName("autor_nome") val autorNome: String?,
    val conteudo: String,
    val tipo: String,                         // texto | imagem | ficheiro
    @SerializedName("ficheiro_url") val ficheiroUrl: String?,
    @SerializedName("created_at")   val criadoEm: String,
    val minha: Boolean = false
)

data class ListaMensagensResponse(
    val ok: Boolean,
    val mensagens: List<Mensagem>
)

data class CriarConversaRequest(
    val tipo: String,
    val nome: String? = null,
    val participantes: List<Long>
)

data class CriarConversaResponse(
    val ok: Boolean,
    val id: Long?
)

data class EnviarMensagemRequest(
    val conteudo: String,
    val tipo: String = "texto"
)

// ── WebSocket events ──────────────────────────────────────────────────────────

data class WsEnvelope(
    val type: String,
    val data: Any?
)

data class WsMessage(
    val type: String,
    @SerializedName("conversa_id") val conversaId: Long = 0,
    val conteudo: String = ""
)

data class WsMensagemRecebida(
    val id: Long,
    @SerializedName("conversa_id") val conversaId: Long,
    @SerializedName("autor_id")    val autorId: Long,
    @SerializedName("autor_nome")  val autorNome: String?,
    val conteudo: String,
    val tipo: String,
    @SerializedName("created_at")  val criadoEm: String,
    val minha: Boolean
)

data class WsJoined(
    @SerializedName("user_id")      val userId: Long,
    @SerializedName("online_users") val onlineUsers: List<Long>
)

data class WsTyping(
    @SerializedName("user_id")     val userId: Long,
    @SerializedName("conversa_id") val conversaId: Long
)

data class UtilizadorChat(
    val id: Long,
    val nome: String,
    val email: String
)

data class ListaUtilizadoresResponse(
    val ok: Boolean,
    val utilizadores: List<UtilizadorChat>
)
