package tech.e258tech.nexora_mobile.data.api

import com.google.gson.Gson
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import okhttp3.Route
import tech.e258tech.nexora_mobile.data.local.TokenManager
import tech.e258tech.nexora_mobile.data.model.RefreshResponse

class TokenAuthenticator(
    private val tokenManager: TokenManager,
    private val baseUrl: String,
    private val gson: Gson,
) : Authenticator {

    private val refreshClient = OkHttpClient()
    private val lock = Any()

    override fun authenticate(route: Route?, response: Response): Request? {
        if (responseCount(response) >= 2) return null
        if (response.request.url.encodedPath.endsWith("/api/auth/refresh")) return null

        val requestToken = response.request.header("Authorization")?.removePrefix("Bearer ")

        return synchronized(lock) {
            runBlocking {
                val currentToken = tokenManager.getAccessToken()
                if (!currentToken.isNullOrBlank() && currentToken != requestToken) {
                    return@runBlocking response.request.newBuilder()
                        .header("Authorization", "Bearer $currentToken")
                        .build()
                }

                val refreshToken = tokenManager.getRefreshToken() ?: return@runBlocking null
                val refreshed = refreshAccessToken(refreshToken) ?: run {
                    tokenManager.clear()
                    return@runBlocking null
                }

                tokenManager.updateAccessToken(refreshed.accessToken, refreshed.expiresIn)
                response.request.newBuilder()
                    .header("Authorization", "Bearer ${refreshed.accessToken}")
                    .build()
            }
        }
    }

    private fun refreshAccessToken(refreshToken: String): RefreshResponse? {
        val body = gson.toJson(mapOf("refresh_token" to refreshToken))
            .toRequestBody("application/json; charset=utf-8".toMediaType())

        val request = Request.Builder()
            .url("${baseUrl.trimEnd('/')}/api/auth/refresh")
            .post(body)
            .build()

        return try {
            refreshClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return null
                response.body?.string()?.let { gson.fromJson(it, RefreshResponse::class.java) }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun responseCount(response: Response): Int {
        var count = 1
        var prior = response.priorResponse
        while (prior != null) {
            count++
            prior = prior.priorResponse
        }
        return count
    }
}
