package tech.e258tech.nexora_assiduidade.data.model.response

data class RefreshTokenResponse(
    val access_token: String,
    val refresh_token: String,
    val token_type: String,
    val expires_in: Int
)
