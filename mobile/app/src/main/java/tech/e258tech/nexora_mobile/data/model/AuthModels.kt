package tech.e258tech.nexora_mobile.data.model

import com.google.gson.annotations.SerializedName

// ── Request ───────────────────────────────────────────────────────────────────

data class LoginRequest(
    val email: String,
    val password: String
)

// ── Response ──────────────────────────────────────────────────────────────────

data class LoginResponse(
    @SerializedName("access_token")  val accessToken: String,
    @SerializedName("refresh_token") val refreshToken: String,
    @SerializedName("expires_in")    val expiresIn: Int,
    @SerializedName("token_type")    val tokenType: String,
    val tipo: String,
    val user: UserInfo,
    val modulos: List<ModuloAcesso>
)

data class UserInfo(
    val id: Long,
    val nome: String,
    val email: String,
    val cargo: String?
)

data class ModuloAcesso(
    val modulo: String,
    val acoes: List<String>
)

data class RefreshRequest(
    @SerializedName("refresh_token") val refreshToken: String
)

data class RefreshResponse(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("expires_in")   val expiresIn: Int
)

data class ApiError(
    val error: String
)

/** Resposta de GET /api/auth/me/acesso — permissões actuais do token (lidas da BD em tempo real). */
data class MeuAcessoResponse(
    @SerializedName("user_id")   val userId: Long,
    @SerializedName("tenant_id") val tenantId: Long,
    val tipo: String,
    val modulos: List<ModuloAcesso>
)
