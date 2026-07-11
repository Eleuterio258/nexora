package tech.e258tech.nexora_assiduidade.data.model.response

import tech.e258tech.nexora_assiduidade.data.model.Meeting

data class MeetingDetailResponse(
    val success: Boolean,
    val message: String,
    val data: Meeting
)
