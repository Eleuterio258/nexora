package tech.e258tech.nexora_assiduidade.data.model.response

data class JustificacaoCreateResponse(
    val id: Long
)

data class JustificacaoResponse(
    val id: Long,
    val tipo: String,
    val data: String,
    val motivo: String,
    val estado: String,
    val created_at: String
)
