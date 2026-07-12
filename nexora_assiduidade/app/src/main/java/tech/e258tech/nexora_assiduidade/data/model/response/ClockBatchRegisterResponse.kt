package tech.e258tech.nexora_assiduidade.data.model.response

data class ClockBatchRegisterResponse(
    val total: Int,
    val accepted: List<ClockBatchAcceptedItem> = emptyList(),
    val rejected: List<ClockBatchRejectedItem> = emptyList()
)

data class ClockBatchAcceptedItem(
    val idempotency_key: String,
    val record_id: String
)

data class ClockBatchRejectedItem(
    val idempotency_key: String,
    val status_code: Int,
    val detail: String?
)
