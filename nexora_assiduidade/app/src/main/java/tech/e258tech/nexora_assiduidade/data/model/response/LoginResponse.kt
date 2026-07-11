package tech.e258tech.nexora_assiduidade.data.model.response

import tech.e258tech.nexora_assiduidade.data.model.AuthenticatedUser

data class LoginResponse(
    val access_token: String,
    val refresh_token: String,
    val token_type: String,
    val expires_in: Int,
    val user: AuthenticatedUser
)
