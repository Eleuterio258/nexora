package tech.e258tech.nexora_assiduidade.data.model

/**
 * GET /api/utilizadores/{userId}/notifications (ERP, Go) — ver
 * backend/internal/modules/utilizadores/handlers/notificacoes.go
 * (ListarNotificacoes). Campos alinhados 1:1 com a linha devolvida pelo SELECT.
 */
data class Notification(
    val id: Long,
    val tipo: String,
    val titulo: String,
    val mensagem: String,
    val lida: Boolean,
    val lida_em: String?,
    val created_at: String
)
