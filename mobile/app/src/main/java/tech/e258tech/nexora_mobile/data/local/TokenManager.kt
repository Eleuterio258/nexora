package tech.e258tech.nexora_mobile.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore("nexora_tokens")

class TokenManager(private val context: Context) {

    companion object {
        private val KEY_ACCESS_TOKEN  = stringPreferencesKey("access_token")
        private val KEY_REFRESH_TOKEN = stringPreferencesKey("refresh_token")
        private val KEY_EXPIRES_AT    = longPreferencesKey("expires_at")
        private val KEY_USER_ID       = longPreferencesKey("user_id")
        private val KEY_USER_NOME     = stringPreferencesKey("user_nome")
        private val KEY_USER_EMAIL    = stringPreferencesKey("user_email")
        private val KEY_USER_TIPO     = stringPreferencesKey("user_tipo")
        private val KEY_USER_MODULOS  = stringPreferencesKey("user_modulos")
    }

    val accessTokenFlow: Flow<String?> = context.dataStore.data.map { it[KEY_ACCESS_TOKEN] }
    val isLoggedIn: Flow<Boolean>      = context.dataStore.data.map { !it[KEY_ACCESS_TOKEN].isNullOrEmpty() }

    suspend fun saveTokens(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        userId: Long,
        nome: String,
        email: String,
        tipo: String,
        modulosJson: String
    ) {
        context.dataStore.edit { prefs ->
            prefs[KEY_ACCESS_TOKEN]  = accessToken
            prefs[KEY_REFRESH_TOKEN] = refreshToken
            prefs[KEY_EXPIRES_AT]    = System.currentTimeMillis() + (expiresIn * 1000L)
            prefs[KEY_USER_ID]       = userId
            prefs[KEY_USER_NOME]     = nome
            prefs[KEY_USER_EMAIL]    = email
            prefs[KEY_USER_TIPO]     = tipo
            prefs[KEY_USER_MODULOS]  = modulosJson
        }
    }

    suspend fun updateAccessToken(accessToken: String, expiresIn: Int) {
        context.dataStore.edit { prefs ->
            prefs[KEY_ACCESS_TOKEN] = accessToken
            prefs[KEY_EXPIRES_AT]   = System.currentTimeMillis() + (expiresIn * 1000L)
        }
    }

    suspend fun getAccessToken(): String?  = context.dataStore.data.first()[KEY_ACCESS_TOKEN]
    suspend fun getRefreshToken(): String? = context.dataStore.data.first()[KEY_REFRESH_TOKEN]
    suspend fun getUserId(): Long          = context.dataStore.data.first()[KEY_USER_ID] ?: 0L
    suspend fun getUserNome(): String      = context.dataStore.data.first()[KEY_USER_NOME] ?: ""
    suspend fun getUserEmail(): String     = context.dataStore.data.first()[KEY_USER_EMAIL] ?: ""
    suspend fun getUserTipo(): String      = context.dataStore.data.first()[KEY_USER_TIPO] ?: ""
    suspend fun getUserModulosJson(): String = context.dataStore.data.first()[KEY_USER_MODULOS] ?: "[]"

    /** Actualiza apenas a lista de módulos (chamado após GET /api/auth/me/acesso). */
    suspend fun saveModulosJson(json: String) {
        context.dataStore.edit { prefs -> prefs[KEY_USER_MODULOS] = json }
    }

    suspend fun isTokenExpired(): Boolean {
        val expiresAt = context.dataStore.data.first()[KEY_EXPIRES_AT] ?: 0L
        return System.currentTimeMillis() >= expiresAt - 60_000L // 1 min de margem
    }

    suspend fun clear() {
        context.dataStore.edit { it.clear() }
    }
}
