package tech.e258tech.nexora_assiduidade.data.model

data class QRGenerateDeviceRequest(
    val location_id: String? = null,
    val duracao_segundos: Int = 60,
    val funcionario_id: Long? = null
)

data class QRValidateDeviceRequest(
    val qr_code: String
)
