package tech.e258tech.nexora_assiduidade.data.model

/**
 * Payload para pedir um desafio de prova de vida ao FaceClock (via ERP).
 * O user_id é preenchido pela app, mas o ERP sobrescreve a partir do JWT.
 */
data class LivenessChallengeRequest(
    val user_id: String
)
