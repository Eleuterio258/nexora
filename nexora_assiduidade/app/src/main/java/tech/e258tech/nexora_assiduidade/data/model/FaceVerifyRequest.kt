package tech.e258tech.nexora_assiduidade.data.model

data class FaceVerifyRequest(
    val user_id: String,
    val device_id: String,
    val image_base64: String,
    val geo_lat: Double? = null,
    val geo_lng: Double? = null
)
