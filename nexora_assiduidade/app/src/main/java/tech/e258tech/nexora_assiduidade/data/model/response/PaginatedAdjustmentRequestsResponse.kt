package tech.e258tech.nexora_assiduidade.data.model.response

data class PaginatedAdjustmentRequestsResponse(
    val items: List<AdjustmentRequestResponse>,
    val page: Int,
    val page_size: Int,
    val total: Int
)
