package tech.e258tech.nexora_assiduidade.data.model.response

data class PaginatedClockRecordsResponse(
    val items: List<ClockRecordResponse>,
    val page: Int,
    val page_size: Int,
    val total: Int
)
