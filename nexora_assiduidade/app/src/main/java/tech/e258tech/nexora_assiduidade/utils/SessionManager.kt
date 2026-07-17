package tech.e258tech.nexora_assiduidade.utils

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import tech.e258tech.nexora_assiduidade.data.model.response.ErpModuloAcesso
import java.util.UUID

/**
 * Gestor de sessao com EncryptedSharedPreferences.
 *
 * Dados sensiveis (token, refresh token, IDs do utilizador) sao armazenados
 * de forma criptografada no dispositivo. E feita uma migracao one-time a partir
 * do SharedPreferences legado (plain) para nao perder sessoes ativas durante
 * o desenvolvimento.
 */
class SessionManager(context: Context) {

    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }

    private val encryptedPrefs: SharedPreferences by lazy {
        EncryptedSharedPreferences.create(
            context,
            Constants.PREFS_NAME_ENCRYPTED,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    private val legacyPrefs: SharedPreferences by lazy {
        context.getSharedPreferences(Constants.PREFS_NAME, Context.MODE_PRIVATE)
    }

    init {
        migrateFromLegacyIfNeeded()
    }

    /**
     * Migra dados do SharedPreferences legado (plain) para o criptografado,
     * apenas uma vez. Os dados legados sao removidos apos a migracao.
     */
    private fun migrateFromLegacyIfNeeded() {
        if (encryptedPrefs.getBoolean(Constants.KEY_MIGRATED_FROM_LEGACY, false)) {
            return
        }

        if (!legacyPrefs.getBoolean(Constants.KEY_IS_LOGGED_IN, false)) {
            encryptedPrefs.edit().putBoolean(Constants.KEY_MIGRATED_FROM_LEGACY, true).apply()
            return
        }

        val editor = encryptedPrefs.edit()
        editor.putString(Constants.KEY_USER_TOKEN, legacyPrefs.getString(Constants.KEY_USER_TOKEN, null))
        editor.putString(Constants.KEY_REFRESH_TOKEN, legacyPrefs.getString(Constants.KEY_REFRESH_TOKEN, null))
        editor.putString(Constants.KEY_USER_ID, legacyPrefs.getString(Constants.KEY_USER_ID, null))
        editor.putString(Constants.KEY_USER_NAME, legacyPrefs.getString(Constants.KEY_USER_NAME, null))
        editor.putString(Constants.KEY_USER_EMAIL, legacyPrefs.getString(Constants.KEY_USER_EMAIL, null))
        editor.putString(Constants.KEY_USER_ROLE, legacyPrefs.getString(Constants.KEY_USER_ROLE, null))
        editor.putString(Constants.KEY_EMPLOYEE_CODE, legacyPrefs.getString(Constants.KEY_EMPLOYEE_CODE, null))
        editor.putString(Constants.KEY_DEVICE_ID, legacyPrefs.getString(Constants.KEY_DEVICE_ID, null))
        editor.putBoolean(Constants.KEY_IS_LOGGED_IN, true)
        editor.putBoolean(Constants.KEY_MIGRATED_FROM_LEGACY, true)
        editor.apply()

        // Remove dados legados para evitar duplicacao e reduzir superficie de ataque.
        legacyPrefs.edit().clear().apply()
    }

    fun saveSession(
        token: String,
        refreshToken: String,
        userId: String,
        userName: String,
        userEmail: String,
        userRole: String,
        employeeCode: String,
        modulos: List<ErpModuloAcesso> = emptyList()
    ) {
        encryptedPrefs.edit().apply {
            putString(Constants.KEY_USER_TOKEN, token)
            putString(Constants.KEY_REFRESH_TOKEN, refreshToken)
            putString(Constants.KEY_USER_ID, userId)
            putString(Constants.KEY_USER_NAME, userName)
            putString(Constants.KEY_USER_EMAIL, userEmail)
            putString(Constants.KEY_USER_ROLE, userRole)
            putString(Constants.KEY_EMPLOYEE_CODE, employeeCode)
            putString(Constants.KEY_MODULOS_JSON, Gson().toJson(modulos))
            putBoolean(Constants.KEY_IS_LOGGED_IN, true)
            apply()
        }
    }

    /** Actualiza só o access token — usado por [tech.e258tech.nexora_assiduidade.data.network.AuthAuthenticator] após renovar a sessão via refresh_token. */
    fun updateAccessToken(token: String) {
        encryptedPrefs.edit().putString(Constants.KEY_USER_TOKEN, token).apply()
    }

    fun isLoggedIn(): Boolean = encryptedPrefs.getBoolean(Constants.KEY_IS_LOGGED_IN, false)

    fun getToken(): String? = encryptedPrefs.getString(Constants.KEY_USER_TOKEN, null)

    /** Permissões RBAC finas devolvidas no login (modulos[].acoes) — ver [PermissionUtils]. */
    fun getModulos(): List<ErpModuloAcesso> {
        val json = encryptedPrefs.getString(Constants.KEY_MODULOS_JSON, null) ?: return emptyList()
        return runCatching {
            val type = object : TypeToken<List<ErpModuloAcesso>>() {}.type
            Gson().fromJson<List<ErpModuloAcesso>>(json, type)
        }.getOrNull() ?: emptyList()
    }

    fun getRefreshToken(): String? = encryptedPrefs.getString(Constants.KEY_REFRESH_TOKEN, null)

    fun getUserId(): String? = encryptedPrefs.getString(Constants.KEY_USER_ID, null)

    fun getUserName(): String? = encryptedPrefs.getString(Constants.KEY_USER_NAME, null)

    fun getUserEmail(): String? = encryptedPrefs.getString(Constants.KEY_USER_EMAIL, null)

    fun getUserRole(): String? = encryptedPrefs.getString(Constants.KEY_USER_ROLE, null)

    fun getEmployeeCode(): String? = encryptedPrefs.getString(Constants.KEY_EMPLOYEE_CODE, null)

    fun getOrCreateDeviceId(): String {
        val existing = encryptedPrefs.getString(Constants.KEY_DEVICE_ID, null)
        if (existing != null) {
            return existing
        }

        val generated = UUID.randomUUID().toString()
        encryptedPrefs.edit().putString(Constants.KEY_DEVICE_ID, generated).apply()
        return generated
    }

    fun clearSession() {
        val deviceId = encryptedPrefs.getString(Constants.KEY_DEVICE_ID, null)
        encryptedPrefs.edit().clear().apply()
        if (deviceId != null) {
            encryptedPrefs.edit().putString(Constants.KEY_DEVICE_ID, deviceId).apply()
        }
    }
}
