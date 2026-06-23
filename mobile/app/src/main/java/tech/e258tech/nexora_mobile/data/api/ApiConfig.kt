package tech.e258tech.nexora_mobile.data.api

import android.content.Context
import com.google.gson.GsonBuilder
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import tech.e258tech.nexora_mobile.BuildConfig
import tech.e258tech.nexora_mobile.data.local.TokenManager
import java.util.concurrent.TimeUnit

object ApiConfig {

    private var retrofit: Retrofit? = null

    fun getApiService(context: Context): ApiService {
        if (retrofit == null) {
            retrofit = buildRetrofit(context)
        }
        return retrofit!!.create(ApiService::class.java)
    }

    private fun buildRetrofit(context: Context): Retrofit {
        val tokenManager = TokenManager(context)

        val logging = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG)
                HttpLoggingInterceptor.Level.BODY
            else
                HttpLoggingInterceptor.Level.NONE
        }

        val gson = GsonBuilder()
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ss")
            .create()

        val client = OkHttpClient.Builder()
            .authenticator(TokenAuthenticator(tokenManager, BuildConfig.API_BASE_URL, gson))
            .addInterceptor(AuthInterceptor(tokenManager))
            .addInterceptor(logging)
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()

        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }

    // URL do WebSocket com token
    fun buildWsUrl(token: String): String =
        "${BuildConfig.WS_BASE_URL}ws/chat?token=${token}"
}
