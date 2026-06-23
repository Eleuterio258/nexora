package tech.e258tech.nexora_mobile.data.repository

import com.google.gson.Gson
import tech.e258tech.nexora_mobile.data.api.ApiService
import tech.e258tech.nexora_mobile.data.local.TokenManager
import tech.e258tech.nexora_mobile.data.model.LoginRequest
import tech.e258tech.nexora_mobile.data.model.LoginResponse
import tech.e258tech.nexora_mobile.data.model.MeuAcessoResponse
import tech.e258tech.nexora_mobile.data.model.ModuloAcesso
import tech.e258tech.nexora_mobile.data.model.RefreshRequest
import tech.e258tech.nexora_mobile.utils.Result
import tech.e258tech.nexora_mobile.utils.safeApiCall

class AuthRepository(
    private val api: ApiService,
    private val tokenManager: TokenManager
) {
    private val gson = Gson()

    suspend fun login(email: String, password: String): Result<LoginResponse> {
        val result = safeApiCall { api.login(LoginRequest(email, password)) }
        if (result is Result.Success) {
            val r = result.data
            tokenManager.saveTokens(
                accessToken  = r.accessToken,
                refreshToken = r.refreshToken,
                expiresIn    = r.expiresIn,
                userId       = r.user.id,
                nome         = r.user.nome,
                email        = r.user.email,
                tipo         = r.tipo,
                modulosJson  = gson.toJson(r.modulos)
            )
        }
        return result
    }

    suspend fun logout() {
        safeApiCall { api.logout() }
        tokenManager.clear()
    }

    suspend fun refreshIfNeeded(): Boolean {
        if (!tokenManager.isTokenExpired()) return true
        val refreshToken = tokenManager.getRefreshToken() ?: return false
        val result = safeApiCall { api.refresh(RefreshRequest(refreshToken)) }
        return if (result is Result.Success) {
            tokenManager.updateAccessToken(result.data.accessToken, result.data.expiresIn)
            true
        } else false
    }

    /**
     * Busca as permissões actuais da API (GET /api/auth/me/acesso).
     * Garante que permissões revogadas são reflectidas imediatamente,
     * sem necessidade de logout/login.
     * Em caso de falha de rede, usa o cache local como fallback.
     */
    suspend fun getModulosActuais(): List<ModuloAcesso> {
        val apiResult = safeApiCall { api.getMeuAcesso() }
        if (apiResult is Result.Success) {
            // Actualizar cache local com permissões frescas
            tokenManager.saveModulosJson(gson.toJson(apiResult.data.modulos))
            return apiResult.data.modulos
        }
        // Fallback: cache local (offline ou erro de rede)
        val json = tokenManager.getUserModulosJson()
        return runCatching {
            gson.fromJson(json, Array<ModuloAcesso>::class.java).toList()
        }.getOrElse { emptyList() }
    }

    fun isLoggedIn() = tokenManager.isLoggedIn
    suspend fun getUserNome()  = tokenManager.getUserNome()
    suspend fun getUserEmail() = tokenManager.getUserEmail()
    suspend fun getUserTipo()  = tokenManager.getUserTipo()
    suspend fun getUserModulosJson() = tokenManager.getUserModulosJson()
    suspend fun getAccessToken() = tokenManager.getAccessToken()
}
