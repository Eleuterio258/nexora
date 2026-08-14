package tech.e258tech.paycore.utils

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.PosLoginResponse
import tech.e258tech.paycore.api.PosRefreshRequest

/**
 * Gerenciador de Token do Terminal
 * Responsável por fazer refresh automático do token do terminal
 */
object TerminalTokenManager {

    private const val TAG = "TerminalTokenManager"
    private const val PREFS_TERMINAL = "terminal_prefs"
    private const val KEY_TERMINAL_TOKEN = "terminal_token"
    private const val KEY_TOKEN_EXPIRES_AT = "token_expires_at"

    // Token expira em 30 dias (2592000 segundos)
    private val TOKEN_VALIDITY_MS = 2592000 * 1000L

    // Fazer refresh quando estiver a menos de 7 dias de expirar
    private val REFRESH_THRESHOLD_MS = 7 * 24 * 60 * 60 * 1000L

    private var isRefreshing = false

    /**
     * Verifica se o token precisa de refresh
     */
    fun needsRefresh(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
        val expiresAt = prefs.getLong(KEY_TOKEN_EXPIRES_AT, 0)
        val now = System.currentTimeMillis()

        // Token expirou ou está perto de expirar
        return expiresAt - now < REFRESH_THRESHOLD_MS
    }

    /**
     * Faz refresh do token do terminal
     */
    suspend fun refreshToken(context: Context): PosLoginResponse? {
        if (isRefreshing) {
            Log.w(TAG, "Refresh já está em andamento")
            return null
        }

        val currentToken = getTerminalToken(context)
        // O refresh do terminal é guardado à parte, em ApiClient (ver
        // ApiClient.saveTerminalTokens, chamado no login) — não neste objecto,
        // que só guarda o access token. O backend (pos_login.go:PosRefresh,
        // ramo tipo="terminal") exige o campo refresh_token, não terminal_token
        // — enviar o access token nesse campo (bug anterior) fazia o pedido
        // falhar sempre com 400 "refresh_token é obrigatório".
        val currentRefreshToken = ApiClient.terminalRefreshToken

        if (currentToken.isNullOrEmpty()) {
            Log.e(TAG, "Token do terminal não encontrado")
            return null
        }
        if (currentRefreshToken.isNullOrEmpty()) {
            Log.e(TAG, "Refresh token do terminal não encontrado")
            return null
        }

        return try {
            isRefreshing = true

            val request = PosRefreshRequest(tipo = "terminal", refreshToken = currentRefreshToken)
            val response = withContext(Dispatchers.IO) {
                ApiClient.service.posRefresh(request)
            }

            if (response.isSuccessful && response.body()?.terminalToken != null) {
                val refreshResponse = response.body()!!

                // Salvar novo token
                saveTerminalToken(context, refreshResponse.terminalToken!!)

                // O backend reemite também um novo refresh_token a cada
                // renovação (issueTerminalTokens, mesmo caminho do login) —
                // guardar em ApiClient, única fonte usada no próximo refresh.
                refreshResponse.terminalRefreshToken?.let { ApiClient.saveTerminalRefreshToken(it) }

                // Calcular nova data de expiração
                val expiresAt = System.currentTimeMillis() + TOKEN_VALIDITY_MS
                saveTokenExpiresAt(context, expiresAt)

                Log.i(TAG, "Token refresh realizado com sucesso")
                refreshResponse
            } else {
                Log.e(TAG, "Erro ao refresh token: ${response.code()} - ${response.message()}")

                // Se o token estiver inválido/expirado, limpar tokens
                if (response.code() == 401) {
                    clearTokens(context)
                }

                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exceção ao refresh token", e)
            null
        } finally {
            isRefreshing = false
        }
    }

    /**
     * Tenta fazer refresh silencioso (sem bloquear a UI)
     * Retorna true se conseguiu refresh ou se o token ainda é válido
     */
    suspend fun refreshIfNeeded(context: Context): Boolean {
        if (!needsRefresh(context)) {
            return true
        }

        Log.i(TAG, "Token precisa de refresh, tentando renovar...")
        val response = refreshToken(context)
        return response != null
    }

    /**
     * Salva o token do terminal
     */
    fun saveTerminalToken(context: Context, token: String) {
        val prefs = context.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_TERMINAL_TOKEN, token).apply()

        // Atualizar também no ApiClient
        ApiClient.saveTerminalToken(token)
    }

    /**
     * Obtém o token do terminal
     */
    fun getTerminalToken(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
        return prefs.getString(KEY_TERMINAL_TOKEN, null)
    }

    /**
     * Salva a data de expiração do token
     */
    private fun saveTokenExpiresAt(context: Context, expiresAt: Long) {
        val prefs = context.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
        prefs.edit().putLong(KEY_TOKEN_EXPIRES_AT, expiresAt).apply()
    }

    /**
     * Obtém a data de expiração do token
     */
    fun getTokenExpiresAt(context: Context): Long {
        val prefs = context.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
        return prefs.getLong(KEY_TOKEN_EXPIRES_AT, 0)
    }

    /**
     * Limpa todos os tokens do terminal
     */
    fun clearTokens(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
        prefs.edit()
            .remove(KEY_TERMINAL_TOKEN)
            .remove(KEY_TOKEN_EXPIRES_AT)
            .apply()

        Log.i(TAG, "Tokens do terminal limpos")
    }

    /**
     * Verifica se o terminal está logado
     */
    fun isTerminalLogged(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_TERMINAL, Context.MODE_PRIVATE)
        val isLogged = prefs.getBoolean("is_terminal_logged", false)
        val hasToken = !getTerminalToken(context).isNullOrEmpty()
        return isLogged && hasToken
    }
}
