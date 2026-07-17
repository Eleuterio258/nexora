package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta de POST /api/auth/login no Nexora ERP (Go) — ver
 * `issueFuncionarioTokens` em backend/internal/modules/auth/handlers/authcode.go:55.
 * `modulos`/`acoes` (permissões RBAC finas) são o que permite derivar se o
 * utilizador é gestor — ver [tech.e258tech.nexora_assiduidade.utils.RoleUtils]
 * e a mesma regra do lado Go em `gatewayAppRole`
 * (backend/internal/modules/auth/handlers/auth.go).
 */
data class ErpLoginResponse(
    val access_token: String,
    val refresh_token: String,
    val token_type: String,
    val expires_in: Int,
    val tipo: String,
    val user: ErpUser,
    val modulos: List<ErpModuloAcesso> = emptyList(),
    val escopo: List<String> = emptyList(),
    val features: List<String> = emptyList()
)

data class ErpUser(
    val id: Long,
    val nome: String,
    val email: String,
    val tenant_id: Long? = null,
    val cargo_id: Long? = null,
    val cargo: String? = null
)

data class ErpModuloAcesso(
    val modulo: String,
    val cor: String? = null,
    val acoes: List<String> = emptyList()
)
