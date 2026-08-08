package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta da validação do desafio de prova de vida.
 * Se match=true, verification_token deve ser usado no POST /ponto.
 */
data class LivenessVerifyResponse(
    val match: Boolean?,
    val user_id: String?,
    val action: String?,
    val action_passed: Boolean?,
    val confidence_score: Double?,
    val liveness_score: Double?,
    val timestamp: String?,
    val reason: String?,
    val verification_token: String?
)
