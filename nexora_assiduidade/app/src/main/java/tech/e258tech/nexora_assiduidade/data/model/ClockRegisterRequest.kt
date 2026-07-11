package tech.e258tech.nexora_assiduidade.data.model

data class ClockRegisterRequest(
    val idempotency_key: String,
    val user_id: String,
    val device_id: String,
    val event_type: String,
    val recorded_at: String,
    val source: String,
    val confidence_score: Double? = null,
    val liveness_score: Double? = null,
    val geo_lat: Double? = null,
    val geo_lng: Double? = null,
    val image_base64: String? = null
)
