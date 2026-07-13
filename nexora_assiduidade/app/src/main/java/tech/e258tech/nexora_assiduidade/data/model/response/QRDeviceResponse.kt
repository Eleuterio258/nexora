package tech.e258tech.nexora_assiduidade.data.model.response

data class QRGenerateDeviceResponse(
    val qr_code: String,
    val expires_at: String
)

data class QRValidateDeviceResponse(
    val valid: Boolean,
    val location_id: String? = null
)
