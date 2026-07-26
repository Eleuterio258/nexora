package tech.e258tech.nexora_assiduidade.data.model

/**
 * Linha de GET /api/crm/leads (ERP, Go) — ver
 * backend/internal/modules/crm/handlers/leads.go:17 (`Lead`).
 */
data class Lead(
    val id: Long,
    val nome: String,
    val empresa: String?,
    val email: String?,
    val telefone: String?,
    val origem: String,
    val estado: String,
    val responsavel: String?,
    val responsavel_id: Long?,
    val notas: String?,
    val cliente_id: Long?,
    val convertido_em: String?,
    val created_at: String,
    val updated_at: String
) {
    companion object {
        /** leads.go:51-57 — "convertido" é terminal, só via /converter. */
        val ESTADOS = linkedMapOf(
            "novo" to "Novo",
            "contactado" to "Contactado",
            "qualificado" to "Qualificado",
            "desqualificado" to "Desqualificado",
            "convertido" to "Convertido"
        )

        /** leads.go:46-49. */
        val ORIGENS = linkedMapOf(
            "site" to "Site",
            "referencia" to "Referência",
            "redes_sociais" to "Redes Sociais",
            "evento" to "Evento",
            "chamada_fria" to "Chamada Fria",
            "email" to "Email",
            "anuncio" to "Anúncio",
            "outro" to "Outro"
        )

        fun estadoLabel(estado: String): String = ESTADOS[estado] ?: estado
        fun origemLabel(origem: String): String = ORIGENS[origem] ?: origem
    }
}

data class LeadListMeta(val total: Int, val page: Int, val limit: Int)

data class LeadListResponse(
    val data: List<Lead>,
    val meta: LeadListMeta
)
