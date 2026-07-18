package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta de POST /api/auth/refresh no Nexora ERP — ver
 * backend/internal/modules/auth/handlers/auth.go:450-455. Não inclui
 * refresh_token novo (o Go não o rotaciona nesta rota).
 */
data class ErpRefreshResponse(
    val access_token: String,
    val token_type: String,
    val expires_in: Int,
    val escopo: List<String> = emptyList()
)
