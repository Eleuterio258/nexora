package tech.e258tech.nexora_assiduidade.data.model

/**
 * Linha de GET /api/crm/oportunidades (ERP, Go) — ver
 * backend/internal/modules/crm/handlers/oportunidades.go:16 (`Oportunidade`).
 */
data class Oportunidade(
    val id: Long,
    val titulo: String,
    val lead_id: Long?,
    val cliente_id: Long?,
    val estagio: String,
    val valor_estimado: Double,
    val moeda: String,
    val probabilidade: Int,
    val data_fecho_prevista: String?,
    val data_fecho_real: String?,
    val motivo_perda: String?,
    val responsavel: String?,
    val responsavel_id: Long?,
    val descricao: String?,
    val created_at: String,
    val updated_at: String
) {
    companion object {
        /** oportunidades.go:49-56 — "ganho"/"perdido" são terminais. */
        val ESTAGIOS = linkedMapOf(
            "novo" to "Novo",
            "qualificado" to "Qualificado",
            "proposta" to "Proposta",
            "negociacao" to "Negociação",
            "ganho" to "Ganho",
            "perdido" to "Perdido"
        )

        val TERMINAIS = setOf("ganho", "perdido")

        fun estagioLabel(estagio: String): String = ESTAGIOS[estagio] ?: estagio
    }
}

data class OportunidadeListMeta(val total: Int, val page: Int, val limit: Int)

data class OportunidadeListResponse(
    val data: List<Oportunidade>,
    val meta: OportunidadeListMeta
)
