package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta de POST /api/authcode/pin/verify e /api/authcode/totp/verify —
 * verificação de um código para um utilizador JÁ AUTENTICADO (prova de
 * presença), sem tokens novos. Ver `VerificarPIN`/`VerificarTOTP` em
 * backend/internal/modules/auth/handlers/authcode.go.
 */
data class AuthCodeVerifyResponse(
    val match: Boolean,
    val reason: String? = null
)
