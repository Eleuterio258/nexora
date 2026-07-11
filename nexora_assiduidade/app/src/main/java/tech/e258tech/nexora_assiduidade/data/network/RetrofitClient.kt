package tech.e258tech.nexora_assiduidade.data.network

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import tech.e258tech.nexora_assiduidade.BuildConfig
import java.util.concurrent.TimeUnit

/**
 * Cliente Retrofit para comunicação com a API
 */
object RetrofitClient {
    
    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = if (BuildConfig.DEBUG) {
            HttpLoggingInterceptor.Level.BODY
        } else {
            HttpLoggingInterceptor.Level.NONE
        }
    }
    
    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()
    
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
