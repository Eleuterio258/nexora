package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta de GET /api/auth/me (backend/internal/modules/auth/handlers/auth.go:630)
 * — usada só para obter a identidade do utilizador (id/nome/email) depois
 * do login via /oauth/token, que não a inclui (ao contrário do antigo
 * /api/auth/login). O payload real tem mais campos (telefone/estado/...);
 * o Gson ignora os que não estão declarados aqui, não é preciso mapeá-los.
 */
data class ErpMeResponse(
    val id: Long,
    val nome: String,
    val email: String,
    val tenant_id: Long? = null
)
