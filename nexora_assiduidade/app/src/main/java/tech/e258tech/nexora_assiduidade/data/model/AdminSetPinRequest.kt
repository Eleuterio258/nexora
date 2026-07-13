package tech.e258tech.nexora_assiduidade.data.model

data class AdminSetPinRequest(
    val user_id: Long,
    val pin: String
)
