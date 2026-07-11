package tech.e258tech.nexora_assiduidade.data.model

data class AdjustmentRequestInput(
    val clock_record_id: String? = null,
    val requested_event_type: String? = null,
    val requested_recorded_at: String? = null,
    val reason: String
)
