package tech.e258tech.nexora_assiduidade.data.network

import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import tech.e258tech.nexora_assiduidade.data.model.ErpRefreshRequest
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Renova a sessão automaticamente num 401, usando o refresh_token guardado
 * — ver POST /api/auth/refresh (backend/internal/modules/auth/handlers/auth.go:402).
 *
 * Corre numa thread de background do OkHttp (nunca a main thread), por isso
 * é seguro bloquear em [refreshApiService]'s `.execute()`. Usa um
 * ErpApiService próprio, servido por um OkHttpClient SEM authenticator
 * (ver [RetrofitClient.refreshApiService]) para nunca entrar em recursão
 * consigo mesmo.
 */
class AuthAuthenticator(
    private val sessionManager: SessionManager,
    private val refreshApiService: ErpApiService
) : Authenticator {

    override fun authenticate(route: Route?, response: Response): Request? {
        // Já tentámos renovar uma vez nesta cadeia e voltou a falhar — desiste
        // (evita loop infinito de 401 -> refresh -> 401 -> refresh -> ...).
        if (responseCount(response) >= 2) {
            return null
        }

        val refreshToken = sessionManager.getRefreshToken() ?: return null

        val novoToken = runCatching {
            refreshApiService.refreshSync(ErpRefreshRequest(refreshToken)).execute()
        }.getOrNull()?.takeIf { it.isSuccessful }?.body()?.access_token

        if (novoToken == null) {
            // refresh_token também expirado/inválido — limpa a sessão; o
            // próximo arranque da app (LoginActivity/MainActivity.onCreate)
            // já redirecciona para o login. Não há redirecionamento imediato
            // a partir daqui (fora de âmbito, ver plano).
            sessionManager.clearSession()
            return null
        }

        sessionManager.updateAccessToken(novoToken)

        return response.request.newBuilder()
            .header("Authorization", ApiUtils.bearerToken(novoToken))
            .build()
    }

    private fun responseCount(response: Response): Int {
        var result = 1
        var prior = response.priorResponse
        while (prior != null) {
            result++
            prior = prior.priorResponse
        }
        return result
    }
}
