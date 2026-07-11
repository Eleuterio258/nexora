package tech.e258tech.nexora_assiduidade.data.model.response

import tech.e258tech.nexora_assiduidade.data.model.Alert

data class AlertListResponse(
    val success: Boolean,
    val message: String,
    val data: List<Alert>
)
