package tech.e258tech.nexora_assiduidade.data.model

data class AuthenticatedUser(
    val id: String,
    val employee_code: String,
    val full_name: String,
    val role: String,
    val status: String
)
