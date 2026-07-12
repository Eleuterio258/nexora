package tech.e258tech.nexora_assiduidade.data.model

import com.google.gson.annotations.SerializedName

/**
 * Body para enviar mensagem via REST (POST /chat/conversas/{id}/mensagens).
 */
data class ChatMessageRequest(
    val conteudo: String,
    val tipo: String = "texto",
    @SerializedName("ficheiro_url")
    val ficheiroUrl: String? = null
)
