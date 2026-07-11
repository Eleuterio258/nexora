package tech.e258tech.nexora_assiduidade.ui.main

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.NfcAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.home.HomeFuncionarioFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.dashboard.DashboardGestorFragment
import tech.e258tech.nexora_assiduidade.utils.RoleUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

class MainActivity : AppCompatActivity() {

    private lateinit var sessionManager: SessionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sessionManager = SessionManager(this)

        if (!sessionManager.isLoggedIn()) {
            navigateToLogin()
            return
        }

        setContentView(R.layout.common_activity_main)

        if (savedInstanceState == null) {
            val initialFragment = if (RoleUtils.isManager(sessionManager.getUserRole())) {
                DashboardGestorFragment()
            } else {
                HomeFuncionarioFragment()
            }
            loadFragment(initialFragment)
        }
    }

    private fun loadFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .commit()
    }

    private fun navigateToLogin() {
        startActivity(Intent(this, LoginActivity::class.java))
        finish()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent ?: return
        val current = supportFragmentManager.findFragmentById(R.id.fragment_container)
        if (current is NfcAttendanceFragment) {
            current.onNewIntent(intent)
        }
    }
}
