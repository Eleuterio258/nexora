package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta do enrollment facial (proxy ERP → FaceClock).
 */
data class EnrollFacialResponse(
    val template_id: String?,
    val user_id: String?,
    val model_version: String?,
    val status: String?
)
