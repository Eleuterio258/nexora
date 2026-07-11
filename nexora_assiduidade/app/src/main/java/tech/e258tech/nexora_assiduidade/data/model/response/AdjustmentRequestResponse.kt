package tech.e258tech.nexora_assiduidade.data.model.response

data class AdjustmentRequestResponse(
    val id: String,
    val user_id: String,
    val clock_record_id: String?,
    val requested_event_type: String?,
    val requested_recorded_at: String?,
    val reason: String,
    val status: String,
    val review_notes: String?,
    val reviewer_id: String?,
    val reviewed_at: String?,
    val created_at: String
)
