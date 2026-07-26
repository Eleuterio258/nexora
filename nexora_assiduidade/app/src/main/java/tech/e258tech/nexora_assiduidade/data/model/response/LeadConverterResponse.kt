package tech.e258tech.nexora_assiduidade.data.model.response

/** Resposta de POST /api/crm/leads/{id}/converter (leads.go:412). */
data class LeadConverterResponse(
    val ok: Boolean,
    val cliente_id: Long?,
    val oportunidade_id: Long?
)
