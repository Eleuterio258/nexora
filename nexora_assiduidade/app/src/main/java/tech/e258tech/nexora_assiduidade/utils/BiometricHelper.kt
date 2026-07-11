package tech.e258tech.nexora_assiduidade.utils

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

/**
 * Helper que encapsula a API BiometricPrompt do AndroidX.
 *
 * IMPORTANTE: A API publica do Android NAO permite obter a imagem da impressao digital,
 * o template biométrico nem identificar qual dedo/pessoa foi reconhecida.
 * Esta classe apenas confirma que o utilizador autenticou com uma biometria valida
 * registada no dispositivo, funcionando como prova de presenca humana vinculada ao
 * login que ja foi efetuado na aplicacao.
 */
object BiometricHelper {

    sealed class BiometricStatus {
        object Available : BiometricStatus()
        data class Unavailable(val reason: String) : BiometricStatus()
    }

    interface AuthenticationCallback {
        fun onSuccess()
        fun onError(errorCode: Int, errorMessage: String)
        fun onFailed()
        fun onCancelled()
    }

    /**
     * Verifica se o dispositivo pode autenticar com biometria forte
     * (impressao digital, face ou iris classificada como Class 3).
     */
    fun checkStatus(activity: FragmentActivity): BiometricStatus {
        val biometricManager = BiometricManager.from(activity)
        return when (biometricManager.canAuthenticate(BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> BiometricStatus.Available
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE ->
                BiometricStatus.Unavailable("Este dispositivo nao possui hardware biometrico.")
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE ->
                BiometricStatus.Unavailable("O sensor biometrico nao esta disponivel.")
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED ->
                BiometricStatus.Unavailable("Nenhuma biometria registada no dispositivo.")
            BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED ->
                BiometricStatus.Unavailable("E necessario atualizar a seguranca do dispositivo.")
            else -> BiometricStatus.Unavailable("Biometria indisponivel neste dispositivo.")
        }
    }

    /**
     * Exibe o prompt de autenticacao biométrica.
     *
     * @param activity Activity que exibe o prompt (deve ser FragmentActivity).
     * @param title Titulo do dialogo.
     * @param subtitle Subtitulo do dialogo.
     * @param description Descricao do dialogo.
     * @param callback Callbacks de resultado.
     */
    fun authenticate(
        activity: FragmentActivity,
        title: String,
        subtitle: String = "",
        description: String = "",
        callback: AuthenticationCallback
    ) {
        val executor = ContextCompat.getMainExecutor(activity)

        val biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    callback.onSuccess()
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    val message = errString.toString()
                    when (errorCode) {
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON -> callback.onCancelled()
                        else -> callback.onError(errorCode, message)
                    }
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    callback.onFailed()
                }
            }
        )

        val promptInfoBuilder = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setAllowedAuthenticators(BIOMETRIC_STRONG)
            .setConfirmationRequired(false)

        if (subtitle.isNotBlank()) {
            promptInfoBuilder.setSubtitle(subtitle)
        }
        if (description.isNotBlank()) {
            promptInfoBuilder.setDescription(description)
        }

        // Para BIOMETRIC_STRONG sem DEVICE_CREDENTIAL, o botao negativo e obrigatorio.
        promptInfoBuilder.setNegativeButtonText("Cancelar")

        biometricPrompt.authenticate(promptInfoBuilder.build())
    }
}
