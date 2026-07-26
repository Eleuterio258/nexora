package tech.e258tech.nexora_assiduidade.data.model

/** Corpo de POST/PUT /api/crm/leads (leads.go:34, `leadInput`). */
data class LeadRequest(
    val nome: String,
    val empresa: String? = null,
    val email: String? = null,
    val telefone: String? = null,
    val origem: String? = null,
    val estado: String? = null,
    val responsavel: String? = null,
    val responsavel_id: Long? = null,
    val notas: String? = null
)
