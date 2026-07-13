package tech.e258tech.nexora_assiduidade.data.model

data class TotpValidateRequest(
    val email: String,
    val code: String
)
