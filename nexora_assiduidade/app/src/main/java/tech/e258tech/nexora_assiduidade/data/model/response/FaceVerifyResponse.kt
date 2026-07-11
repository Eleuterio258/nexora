package tech.e258tech.nexora_assiduidade.data.model.response

data class FaceVerifyResponse(
    val match: Boolean,
    val user_id: String?,
    val confidence_score: Double?,
    val liveness_score: Double?,
    val timestamp: String?,
    val reason: String?
)
