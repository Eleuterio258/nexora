package tech.e258tech.nexora_assiduidade.data.network

import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Renova a sessão automaticamente num 401, usando o refresh_token guardado
 * — ver POST /oauth/token, grant_type=refresh_token (Authorization Server
 * OAuth2, backend/internal/modules/auth/handlers/oauth_token.go).
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

    // OkHttp pode invocar authenticate() a partir de vários threads em
    // simultâneo (não há lock implícito — é a própria doc do Authenticator
    // que o diz). Sem isto, dois 401 concorrentes disparavam dois refreshes
    // com o MESMO refresh_token: o ERP roda-o a cada uso e trata a
    // reutilização de um já consumido como token comprometido, revogando a
    // família inteira — logout forçado só por coincidência de timing (ex.:
    // um ecrã a disparar vários pedidos em paralelo mesmo quando o access
    // token expira), não por o token estar realmente expirado ou roubado.
    private val refreshLock = Any()

    override fun authenticate(route: Route?, response: Response): Request? {
        // Já tentámos renovar uma vez nesta cadeia e voltou a falhar — desiste
        // (evita loop infinito de 401 -> refresh -> 401 -> refresh -> ...).
        if (responseCount(response) >= 2) {
            return null
        }

        synchronized(refreshLock) {
            // Outro thread já renovou entretanto, enquanto este esperava pelo
            // lock — o Authorization usado no pedido que falhou já não é o
            // actual. Reutiliza o token já renovado em vez de disparar mais
            // um refresh com um refresh_token que o ERP já rodou.
            val currentToken = sessionManager.getToken()
            if (currentToken != null &&
                response.request.header("Authorization") != ApiUtils.bearerToken(currentToken)
            ) {
                return response.request.newBuilder()
                    .header("Authorization", ApiUtils.bearerToken(currentToken))
                    .build()
            }

            val refreshToken = sessionManager.getRefreshToken() ?: return null

            // O ERP RODA o refresh_token a cada uso — o corpo desta resposta traz
            // sempre um novo refresh_token, que TEM de ser persistido (senão a
            // próxima renovação apresenta um token já revogado e o ERP trata isso
            // como reuse de token comprometido, revogando a sessão inteira).
            val novoTokens = runCatching {
                refreshApiService.oauthRefreshSync(refreshToken).execute()
            }.getOrNull()?.takeIf { it.isSuccessful }?.body()

            if (novoTokens == null) {
                // refresh_token também expirado/inválido — limpa a sessão; o
                // próximo arranque da app (LoginActivity/MainActivity.onCreate)
                // já redirecciona para o login. Não há redirecionamento imediato
                // a partir daqui (fora de âmbito, ver plano).
                sessionManager.clearSession()
                return null
            }

            sessionManager.updateAccessToken(novoTokens.access_token)
            sessionManager.updateRefreshToken(novoTokens.refresh_token)

            return response.request.newBuilder()
                .header("Authorization", ApiUtils.bearerToken(novoTokens.access_token))
                .build()
        }
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
