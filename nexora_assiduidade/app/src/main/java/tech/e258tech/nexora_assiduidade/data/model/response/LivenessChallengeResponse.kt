package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta do desafio de prova de vida.
 */
data class LivenessChallengeResponse(
    val challenge_id: String?,
    val action: String?,
    val prompt: String?,
    val expires_in_seconds: Int?
)
