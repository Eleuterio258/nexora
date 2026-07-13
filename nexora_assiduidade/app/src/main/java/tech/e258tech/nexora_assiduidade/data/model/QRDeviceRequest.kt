package tech.e258tech.nexora_assiduidade.data.model

data class QRGenerateDeviceRequest(
    val location_id: String? = null,
    val duracao_segundos: Int = 60
)

data class QRValidateDeviceRequest(
    val qr_code: String
)
