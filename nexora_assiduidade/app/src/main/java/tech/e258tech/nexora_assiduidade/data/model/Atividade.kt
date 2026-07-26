package tech.e258tech.nexora_assiduidade.data.model

/**
 * Linha de GET /api/crm/atividades (ERP, Go) — ver
 * backend/internal/modules/crm/handlers/atividades.go:15 (`Atividade`).
 */
data class Atividade(
    val id: Long,
    val lead_id: Long?,
    val oportunidade_id: Long?,
    val tipo: String,
    val titulo: String,
    val descricao: String?,
    val data_atividade: String?,
    val concluida: Boolean,
    val responsavel: String?,
    val created_at: String,
    val updated_at: String
) {
    companion object {
        /** atividades.go:39-41. */
        val TIPOS = linkedMapOf(
            "nota" to "Nota",
            "tarefa" to "Tarefa",
            "chamada" to "Chamada",
            "reuniao" to "Reunião",
            "email" to "Email"
        )

        fun tipoLabel(tipo: String): String = TIPOS[tipo] ?: tipo
    }
}

data class AtividadeListMeta(val total: Int, val page: Int, val limit: Int)

data class AtividadeListResponse(
    val data: List<Atividade>,
    val meta: AtividadeListMeta
)
