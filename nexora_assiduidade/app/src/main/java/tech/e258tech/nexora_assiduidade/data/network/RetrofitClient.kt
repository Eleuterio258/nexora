package tech.e258tech.nexora_assiduidade.data.network

import android.content.Context
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import java.util.concurrent.TimeUnit

/**
 * Cliente Retrofit para comunicação com a API
 */
object RetrofitClient {

    private lateinit var sessionManager: SessionManager

    /** Chamado uma única vez, a partir de [tech.e258tech.nexora_assiduidade.NexoraApplication.onCreate]. */
    fun init(context: Context) {
        if (::sessionManager.isInitialized) return
        sessionManager = SessionManager(context.applicationContext)
    }

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = if (BuildConfig.DEBUG) {
            HttpLoggingInterceptor.Level.BODY
        } else {
            HttpLoggingInterceptor.Level.NONE
        }
    }

    // Cliente "base", sem authenticator — usado pelo próprio refreshApiService,
    // para nunca entrar em recursão consigo mesmo num 401 do refresh.
    private val baseOkHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val refreshRetrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(BuildConfig.ERP_BASE_URL)
            .client(baseOkHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    private val refreshApiService: ErpApiService by lazy {
        refreshRetrofit.create(ErpApiService::class.java)
    }

    // Cliente "principal" — com authenticator, renova a sessão sozinho num 401.
    private val okHttpClient: OkHttpClient by lazy {
        baseOkHttpClient.newBuilder()
            .authenticator(AuthAuthenticator(sessionManager, refreshApiService))
            .build()
    }

    private val erpRetrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(BuildConfig.ERP_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    private val assiduidadeRetrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(BuildConfig.ASSIDUIDADE_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    val erpApiService: ErpApiService by lazy {
        erpRetrofit.create(ErpApiService::class.java)
    }

    val assiduidadeApiService: AssiduidadeApiService by lazy {
        assiduidadeRetrofit.create(AssiduidadeApiService::class.java)
    }
}
