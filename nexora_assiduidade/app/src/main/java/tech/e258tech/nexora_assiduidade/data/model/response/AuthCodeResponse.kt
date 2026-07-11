package tech.e258tech.nexora_assiduidade.data.model.response

data class AuthCodeResponse(
    val valid: Boolean,
    val method: String,
    val message: String
)
