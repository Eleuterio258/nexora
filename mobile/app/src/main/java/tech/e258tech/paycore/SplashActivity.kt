package tech.e258tech.paycore

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.repository.SessionRepository
import tech.e258tech.paycore.ui.LoginTerminalActivity

class SplashActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)

        // Restaurar dados do terminal configurado neste device.
        val prefs      = getSharedPreferences(LoginTerminalActivity.PREFS_TERMINAL, MODE_PRIVATE)
        val tenantId   = prefs.getString(LoginTerminalActivity.KEY_TENANT_ID, "").orEmpty()
        val tenantNome = prefs.getString(LoginTerminalActivity.KEY_TENANT_NOME, "").orEmpty()
        val terminalId = prefs.getString(LoginTerminalActivity.KEY_TERMINAL_ID, "").orEmpty()

        if (tenantId.isNotEmpty())   SessionRepository.tenantId   = tenantId
        if (tenantNome.isNotEmpty()) SessionRepository.tenantNome = tenantNome
        if (terminalId.isNotEmpty()) SessionRepository.terminalId = terminalId

        // Routing imediato — sem atraso artificial:
        // 1. Terminal ainda não configurado neste device? → Ativar terminal.
        // 2. Funcionário já logado?  → Desbloqueio rápido (PIN/biometria).
        // 3. Onboarding ainda não visto?  → Onboarding (só na primeira vez)
        // 4. Sem licença/tenant activado neste aparelho?  → Ativação de licença
        // 5. Caso contrário  → Login do funcionário
        val onboardingVisto = getSharedPreferences(OnboardingActivity.PREFS_APP, MODE_PRIVATE)
            .getBoolean(OnboardingActivity.KEY_ONBOARDING_VISTO, false)
        val terminalConfigurado = terminalId.isNotEmpty()
        val destino = when {
            !terminalConfigurado -> LoginTerminalActivity::class.java
            ApiClient.isLoggedIn && SessionRepository.operadorAtual != null -> PinLoginActivity::class.java
            !onboardingVisto -> OnboardingActivity::class.java
            tenantId.isEmpty() -> AtivacaoLicencaActivity::class.java
            else -> LoginActivity::class.java
        }

        startActivity(Intent(this, destino).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        })
        finish()
    }
}
