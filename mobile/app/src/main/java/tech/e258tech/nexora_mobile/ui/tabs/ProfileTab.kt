package tech.e258tech.nexora_mobile.ui.tabs

import android.content.Intent
import android.graphics.Color
import android.widget.Toast
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.app
import tech.e258tech.nexora_mobile.ui.screens.login.LoginActivity
import tech.e258tech.nexora_mobile.ui.screens.main.MainActivity

internal class ProfileTab(private val activity: MainActivity) {

    fun show() {
        activity.binding.mainContent.apply {
            setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
            removeAllViews()
            addView(activity.buildPageTitle("Perfil", "Dados da conta, empresa e preferencias."))
            addView(activity.buildActionRow(
                title = "Administrador",
                subtitle = "admin@nexora.co.mz",
                iconRes = android.R.drawable.ic_menu_myplaces,
            ) { Toast.makeText(activity, "Dados do utilizador", Toast.LENGTH_SHORT).show() })
            addView(activity.buildDivider())
            addView(activity.buildActionRow(
                title = "Empresa",
                subtitle = "Nexora ERP Demo - Maputo",
                iconRes = android.R.drawable.ic_menu_compass,
            ) { Toast.makeText(activity, "Dados da empresa", Toast.LENGTH_SHORT).show() })
            addView(activity.buildDivider())
            addView(activity.buildActionRow(
                title = "Perfil de acesso",
                subtitle = "Administrador geral",
                iconRes = android.R.drawable.ic_menu_manage,
            ) { Toast.makeText(activity, "Perfil de acesso", Toast.LENGTH_SHORT).show() })
            addView(activity.buildDivider())
            addView(activity.buildActionRow(
                title = "Seguranca",
                subtitle = "Password e sessoes activas",
                iconRes = android.R.drawable.ic_lock_lock,
            ) { Toast.makeText(activity, "Seguranca", Toast.LENGTH_SHORT).show() })
            addView(activity.buildDivider())
            addView(activity.buildActionRow(
                title = "Terminar sessao",
                subtitle = "Sair desta conta no dispositivo",
                iconRes = android.R.drawable.ic_lock_power_off,
                iconColor = Color.parseColor("#DC2626"),
                onClick = { doLogout() },
            ))
        }
    }

    private fun doLogout() {
        activity.lifecycleScope.launch {
            activity.app.chatRepository.disconnect()
            activity.app.authRepository.logout()
            val intent = Intent(activity, LoginActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            activity.startActivity(intent)
        }
    }
}
