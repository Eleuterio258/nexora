package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta de POST /api/authcode/totp/setup no Nexora ERP — ver
 * `SetupTOTP` em backend/internal/modules/auth/handlers/authcode.go.
 */
data class TotpSetupResponse(
    val secret: String,
    val provisioning_uri: String
)
