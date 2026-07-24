package tech.e258tech.nexora_assiduidade.data.model

/**
 * GET/POST /api/utilizadores/{userId}/agenda (ERP, Go) — ver
 * backend/internal/modules/utilizadores/handlers/agenda.go
 * (ListarAgenda/CriarItemAgenda). Campos alinhados 1:1 com a linha devolvida pelo SELECT.
 */
data class AgendaItem(
    val id: Long,
    val titulo: String,
    val descricao: String?,
    val data: String,
    val hora_inicio: String,
    val hora_fim: String?,
    val tipo: String,
    val created_at: String
)

data class AgendaItemRequest(
    val titulo: String,
    val descricao: String?,
    val data: String,
    val hora_inicio: String,
    val hora_fim: String?,
    val tipo: String = "reuniao"
)
