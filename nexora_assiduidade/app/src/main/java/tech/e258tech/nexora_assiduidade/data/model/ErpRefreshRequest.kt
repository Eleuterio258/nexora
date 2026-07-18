package tech.e258tech.nexora_assiduidade.data.model

/**
 * Payload de POST /api/auth/refresh no Nexora ERP — ver
 * backend/internal/modules/auth/handlers/auth.go:402 (Refresh).
 */
data class ErpRefreshRequest(
    val refresh_token: String
)
