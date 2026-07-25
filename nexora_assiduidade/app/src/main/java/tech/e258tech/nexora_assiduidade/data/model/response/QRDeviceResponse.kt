package tech.e258tech.nexora_assiduidade.data.model.response

data class QRGenerateDeviceResponse(
    val qr_code: String,
    val expires_at: String,
    val funcionario_id: Long? = null
)

data class QRValidateDeviceResponse(
    val valid: Boolean,
    val token_id: Long? = null,
    val location_id: String? = null,
    val funcionario_id: Long? = null,
    val employee_no: String? = null
)
