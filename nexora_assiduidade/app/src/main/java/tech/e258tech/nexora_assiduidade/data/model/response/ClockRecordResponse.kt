package tech.e258tech.nexora_assiduidade.data.model.response

data class ClockRecordResponse(
    val id: String,
    val user_id: String,
    val device_id: String?,
    val event_type: String,
    val recorded_at: String,
    val source: String,
    val sync_status: String,
    val confidence_score: Double?,
    val liveness_score: Double?,
    val created_at: String
)
