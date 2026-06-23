package tech.e258tech.nexora_mobile

import android.app.Application
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import tech.e258tech.nexora_mobile.data.api.ApiConfig
import tech.e258tech.nexora_mobile.data.api.ApiService
import tech.e258tech.nexora_mobile.data.local.TokenManager
import tech.e258tech.nexora_mobile.data.repository.*
import java.util.concurrent.TimeUnit

/** Container simples de dependências (sem Hilt/Koin para manter o projecto leve). */
class NexoraApp : Application() {

    lateinit var tokenManager: TokenManager       private set
    lateinit var apiService: ApiService           private set
    lateinit var okHttpClient: OkHttpClient       private set

    lateinit var authRepository: AuthRepository   private set
    lateinit var homeRepository: HomeRepository   private set
    lateinit var feriasRepository: FeriasRepository private set
    lateinit var assiduidadeRepository: AssiduidadeRepository private set
    lateinit var perfilRepository: PerfilRepository private set
    lateinit var chatRepository: ChatRepository   private set

    override fun onCreate() {
        super.onCreate()

        tokenManager = TokenManager(this)
        apiService   = ApiConfig.getApiService(this)

        // OkHttp partilhado (para o WebSocket do Chat)
        okHttpClient = OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BASIC
                        else HttpLoggingInterceptor.Level.NONE
            })
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(0, TimeUnit.SECONDS)   // 0 = sem timeout (WebSocket)
            .build()

        authRepository       = AuthRepository(apiService, tokenManager)
        homeRepository       = HomeRepository(apiService)
        feriasRepository     = FeriasRepository(apiService)
        assiduidadeRepository = AssiduidadeRepository(apiService)
        perfilRepository     = PerfilRepository(apiService)
        chatRepository       = ChatRepository(apiService, okHttpClient)
    }
}

// Extension para aceder ao container de qualquer Activity/Fragment
val android.content.Context.app get() = applicationContext as NexoraApp
