package tech.e258tech.nexora_mobile.data.api

import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response
import tech.e258tech.nexora_mobile.data.local.TokenManager

class AuthInterceptor(private val tokenManager: TokenManager) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val token = runBlocking { tokenManager.getAccessToken() }

        val request = if (!token.isNullOrEmpty()) {
            chain.request().newBuilder()
                .addHeader("Authorization", "Bearer $token")
                .build()
        } else {
            chain.request()
        }

        return chain.proceed(request)
    }
}
