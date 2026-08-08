package tech.e258tech.nexora_assiduidade.data.model

/**
 * Payload para validar o desafio de prova de vida + match facial.
 */
data class LivenessVerifyRequest(
    val challenge_id: String,
    val device_id: String,
    val frames_base64: List<String>,
    val geo_lat: Double? = null,
    val geo_lng: Double? = null
)
