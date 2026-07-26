package tech.e258tech.nexora_assiduidade.data.model

/** Corpo de POST /api/crm/leads/{id}/converter (leads.go:302, `converterLeadInput`). */
data class LeadConverterRequest(
    val criar_oportunidade: Boolean,
    val oportunidade_titulo: String? = null,
    val valor_estimado: Double? = null,
    val moeda: String? = null
)
