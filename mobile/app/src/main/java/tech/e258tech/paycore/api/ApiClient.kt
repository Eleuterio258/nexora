package tech.e258tech.paycore.api

import android.content.Context
import android.content.Intent
import android.util.Base64
import com.google.gson.Gson
import okhttp3.Authenticator
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.logging.HttpLoggingInterceptor
import org.json.JSONObject
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import tech.e258tech.paycore.LoginActivity
import java.util.concurrent.TimeUnit

object ApiClient {

    // URL base vem do BuildConfig — pode ser alterada por flavor/build-type sem
    // recompilar o código fonte. Padrão aponta para produção Nexora.
    private const val BASE_URL = tech.e258tech.paycore.BuildConfig.API_BASE_URL

    const val adminWebUrl = tech.e258tech.paycore.BuildConfig.ADMIN_WEB_URL

    private const val PREFS_AUTH          = "auth_prefs"
    // access/refresh agora são do FUNCIONÁRIO
    private const val KEY_ACCESS_TOKEN             = "access_token"
    private const val KEY_REFRESH_TOKEN            = "refresh_token"
    private const val KEY_TERMINAL_TOKEN           = "terminal_token"
    private const val KEY_TERMINAL_REFRESH_TOKEN   = "terminal_refresh_token"

    private lateinit var appContext: Context

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    // ── Token storage ────────────────────────────────────────────────────────

    /** Token de acesso do FUNCIONÁRIO (usado no header Authorization). */
    var accessToken: String?
        get()      = prefs.getString(KEY_ACCESS_TOKEN, null)
        set(value) = prefs.edit().putString(KEY_ACCESS_TOKEN, value).apply()

    /** Refresh token do FUNCIONÁRIO. */
    var refreshToken: String?
        get()      = prefs.getString(KEY_REFRESH_TOKEN, null)
        set(value) = prefs.edit().putString(KEY_REFRESH_TOKEN, value).apply()

    /** Salva tokens de funcionário vindos do ERP /api/auth/login. */
    fun saveEmployeeTokens(login: AuthLoginResponse) {
        prefs.edit()
            .putString(KEY_ACCESS_TOKEN,  login.accessToken)
            .putString(KEY_REFRESH_TOKEN, login.refreshToken)
            .apply()
    }

    /** Salva tokens do terminal (login pos/login tipo=terminal). */
    fun saveTerminalTokens(login: PosLoginResponse) {
        prefs.edit()
            .putString(KEY_TERMINAL_TOKEN,         login.terminalToken)
            .putString(KEY_TERMINAL_REFRESH_TOKEN, login.terminalRefreshToken)
            .apply()
    }

    fun saveTerminalToken(token: String) {
        prefs.edit().putString(KEY_TERMINAL_TOKEN, token).apply()
    }

    fun saveTerminalRefreshToken(token: String) {
        prefs.edit().putString(KEY_TERMINAL_REFRESH_TOKEN, token).apply()
    }

    var terminalToken: String?
        get()      = prefs.getString(KEY_TERMINAL_TOKEN, null)
        set(value) = prefs.edit().putString(KEY_TERMINAL_TOKEN, value).apply()

    var terminalRefreshToken: String?
        get()      = prefs.getString(KEY_TERMINAL_REFRESH_TOKEN, null)
        set(value) = prefs.edit().putString(KEY_TERMINAL_REFRESH_TOKEN, value).apply()

    /** Limpa apenas os tokens do FUNCIONÁRIO (logout de turno). */
    fun clearEmployeeTokens() {
        prefs.edit()
            .remove(KEY_ACCESS_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .apply()
    }

    /** Limpa apenas os tokens do TERMINAL (desativar aparelho). */
    fun clearTerminalTokens() {
        prefs.edit()
            .remove(KEY_TERMINAL_TOKEN)
            .remove(KEY_TERMINAL_REFRESH_TOKEN)
            .apply()
    }

    /** Limpa tudo (funcionário + terminal). */
    fun clearAllTokens() {
        prefs.edit()
            .remove(KEY_ACCESS_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .remove(KEY_TERMINAL_TOKEN)
            .remove(KEY_TERMINAL_REFRESH_TOKEN)
            .apply()
    }

    @Deprecated("Use saveEmployeeTokens ou saveTerminalTokens conforme o contexto")
    fun saveTokens(login: PosLoginResponse) {
        prefs.edit()
            .putString(KEY_ACCESS_TOKEN,  login.accessToken)
            .putString(KEY_REFRESH_TOKEN, login.refreshToken)
            .apply()
    }

    @Deprecated("Use clearEmployeeTokens, clearTerminalTokens ou clearAllTokens")
    fun clearTokens() = clearAllTokens()

    /** Funcionário logado? */
    val isLoggedIn: Boolean get() = accessToken != null

    /** Terminal configurado? */
    val isTerminalConfigured: Boolean get() = terminalToken != null

    private val prefs
        get() = appContext.getSharedPreferences(PREFS_AUTH, Context.MODE_PRIVATE)

    // ── Interceptors ─────────────────────────────────────────────────────────

    private val authInterceptor = Interceptor { chain ->
        // Usa o token do funcionário se existir; caso contrário, usa o token do
        // terminal como fallback (permite chamadas POS mesmo sem sessão de
        // funcionário activa, desde que o terminal esteja configurado).
        //
        // Se houver um token de funcionário mas estiver localmente expirado (exp do
        // JWT no passado), tenta renová-lo já aqui em vez de esperar pelo 401 —
        // mas NUNCA cai para o token do terminal só por o do funcionário parecer
        // expirado: isso faria o pedido correr autenticado como o terminal em vez
        // do funcionário (actor errado). Se a renovação falhar, envia o token
        // expirado mesmo assim — o 401 resultante é apanhado pelo tokenAuthenticator,
        // que partilha a mesma lógica de renovação/logout.
        val storedAccess = accessToken
        val token = when {
            storedAccess != null && !jwtExpirado(storedAccess) -> storedAccess
            storedAccess != null -> tentarRefreshEmployeeToken() ?: storedAccess
            else -> terminalToken
        }
        val request = if (token != null) {
            chain.request().newBuilder()
                .header("Authorization", "Bearer $token")
                .build()
        } else chain.request()
        chain.proceed(request)
    }

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        // BODY (incl. tokens nos headers via authInterceptor) só em debug — em release
        // não há logging de HTTP nenhum.
        level = if (tech.e258tech.paycore.BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BODY else HttpLoggingInterceptor.Level.NONE
    }

    /** true se [token] for um JWT cujo claim "exp" já passou (com margem de 10s). Tokens que não
     * dão para decodificar (formato inesperado) contam como não-expirados — deixa o 401 reactivo
     * tratar em vez de bloquear o pedido por engano. */
    private fun jwtExpirado(token: String): Boolean {
        return try {
            val payload = token.split(".").getOrNull(1) ?: return false
            val decoded = String(Base64.decode(payload, Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP))
            val exp = JSONObject(decoded).optLong("exp", -1)
            exp > 0 && exp * 1000 < System.currentTimeMillis() - 10_000
        } catch (e: Exception) {
            false
        }
    }

    /** Limpa os tokens do funcionário e manda o utilizador de volta ao ecrã de login —
     * chamado sempre que uma falha de renovação é definitiva (não uma simples falha de rede). */
    private fun forcarLogoutEIrParaLogin() {
        clearEmployeeTokens()
        val intent = Intent(appContext, LoginActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        appContext.startActivity(intent)
    }

    // ── Authenticator (401 → refresh token → retry) ──────────────────────────
    //
    // Uses a separate bare OkHttpClient to avoid triggering this authenticator
    // recursively. A synchronized block prevents concurrent refresh storms when
    // multiple requests fail with 401 at the same time.

    private val refreshLock = Any()

    /** Tenta renovar o access token do funcionário (chamada de rede síncrona — nunca correr na
     * main thread). Partilhada entre o [authInterceptor] (renovação proactiva) e o
     * [tokenAuthenticator] (renovação reactiva a um 401). synchronized(refreshLock) é reentrante
     * na mesma thread, por isso é seguro chamar esta função também a partir de dentro do bloco
     * synchronized do tokenAuthenticator.
     *
     * - Sem refresh token guardado, ou pedido de renovação explicitamente rejeitado → a sessão
     *   está definitivamente morta: limpa tokens e manda para o login.
     * - Falha de rede (excepção) → NÃO força logout nem limpa tokens: o refresh token pode
     *   continuar válido, só não há ligação agora (este POS é offline-first). */
    private fun tentarRefreshEmployeeToken(): String? = synchronized(refreshLock) {
        val token = refreshToken ?: run {
            forcarLogoutEIrParaLogin()
            return@synchronized null
        }

        val refreshClient = OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()

        val body = """{"refresh_token":"$token"}"""
            .toRequestBody("application/json".toMediaType())

        val refreshRequest = Request.Builder()
            .url("${BASE_URL}auth/refresh")
            .post(body)
            .build()

        try {
            val res = refreshClient.newCall(refreshRequest).execute()
            if (res.isSuccessful) {
                val parsed = Gson().fromJson(res.body?.string(), AuthLoginResponse::class.java)
                if (parsed?.accessToken != null) {
                    accessToken = parsed.accessToken
                    parsed.refreshToken?.let { refreshToken = it }
                    parsed.accessToken
                } else {
                    forcarLogoutEIrParaLogin()
                    null
                }
            } else {
                forcarLogoutEIrParaLogin()
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    private val tokenAuthenticator = Authenticator { _, response ->
        // Already retried once after a refresh — the refreshed token was still rejected,
        // so the session is definitively dead.
        if (response.request.header("X-Retry-After-Refresh") != null) {
            forcarLogoutEIrParaLogin()
            return@Authenticator null
        }

        if (refreshToken == null) {
            forcarLogoutEIrParaLogin()
            return@Authenticator null
        }

        synchronized(refreshLock) {
            // Another thread may have already refreshed while we were waiting
            val latestAccess = accessToken
            val usedAccess = response.request.header("Authorization")?.removePrefix("Bearer ")
            val tokenParaUsar = if (latestAccess != null && latestAccess != usedAccess && !jwtExpirado(latestAccess)) {
                latestAccess
            } else {
                tentarRefreshEmployeeToken()
            }

            tokenParaUsar?.let {
                response.request.newBuilder()
                    .header("Authorization", "Bearer $it")
                    .header("X-Retry-After-Refresh", "true")
                    .build()
            }
        }
    }

    // ── OkHttp ───────────────────────────────────────────────────────────────

    private val okHttpClient by lazy {
        OkHttpClient.Builder()
            .authenticator(tokenAuthenticator)
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    // ── Retrofit service ─────────────────────────────────────────────────────

    val service: ApiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(ApiService::class.java)
    }
}
