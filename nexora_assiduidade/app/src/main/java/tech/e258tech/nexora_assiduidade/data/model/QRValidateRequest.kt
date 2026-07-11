package tech.e258tech.nexora_assiduidade.data.model

data class QRValidateRequest(
    val qr_code: String,
    val user_id: String? = null
)
