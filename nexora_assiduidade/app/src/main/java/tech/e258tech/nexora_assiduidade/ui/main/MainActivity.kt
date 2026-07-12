package tech.e258tech.nexora_assiduidade.ui.main

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.NfcAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.chat.ChatFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.history.HistoryFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.home.HomeFuncionarioFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.modules.ModulesFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.profile.ProfileFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.requests.RequestsFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.dashboard.DashboardGestorFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.equipa.EquipaGestorFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.ferias.PedidosFeriasFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.mais.MaisFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.relatorios.RelatoriosGestorFragment
import tech.e258tech.nexora_assiduidade.utils.RoleUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import tech.e258tech.nexora_assiduidade.work.SyncAttendanceWorker

enum class BottomTab { HOME, MODULES, CHAT, VACATION, ATTENDANCE, PROFILE }

enum class GestorTab { DASHBOARD, EQUIPA, FERIAS, RELATORIOS, MAIS }

class MainActivity : AppCompatActivity() {

    private lateinit var sessionManager: SessionManager
    private var activeTab: BottomTab? = null
    private var activeGestorTab: GestorTab? = null

    private data class NavItem(
        val container: LinearLayout,
        val icon: ImageView,
        val label: TextView,
        val tab: BottomTab,
        val fragment: () -> Fragment,
    )

    private data class GestorNavItem(
        val container: LinearLayout,
        val icon: ImageView,
        val label: TextView,
        val tab: GestorTab,
        val fragment: () -> Fragment,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sessionManager = SessionManager(this)

        if (!sessionManager.isLoggedIn()) {
            navigateToLogin()
            return
        }

        setContentView(R.layout.common_activity_main)
        SyncAttendanceWorker.schedulePeriodic(this)

        val isManager = RoleUtils.isManager(sessionManager.getUserRole())
        val bottomNav = findViewById<View>(R.id.bottomNavContainer)
        val gestorBottomNav = findViewById<View>(R.id.gestorBottomNavContainer)
        val fragmentContainer = findViewById<View>(R.id.fragment_container)

        if (isManager) {
            bottomNav.visibility = View.GONE
            applyEdgeInsets(fragmentContainer, top = true, bottom = false)
            applyEdgeInsets(gestorBottomNav, top = false, bottom = true)
            setupGestorBottomNav()
            if (savedInstanceState == null) {
                selectGestorTab(GestorTab.DASHBOARD)
            }
        } else {
            gestorBottomNav.visibility = View.GONE
            applyEdgeInsets(fragmentContainer, top = true, bottom = false)
            applyEdgeInsets(bottomNav, top = false, bottom = true)
            setupBottomNav()
            if (savedInstanceState == null) {
                selectTab(BottomTab.HOME)
            }
        }
    }

    /** Empurra a view para dentro da área segura (status bar e/ou gesture/nav bar do sistema, modo edge-to-edge). */
    private fun applyEdgeInsets(view: View, top: Boolean, bottom: Boolean) {
        val basePaddingTop = view.paddingTop
        val basePaddingBottom = view.paddingBottom
        ViewCompat.setOnApplyWindowInsetsListener(view) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(
                v.paddingLeft,
                if (top) basePaddingTop + systemBars.top else v.paddingTop,
                v.paddingRight,
                if (bottom) basePaddingBottom + systemBars.bottom else v.paddingBottom,
            )
            insets
        }
        ViewCompat.requestApplyInsets(view)
    }

    private fun setupBottomNav() {
        val items = listOf(
            NavItem(
                findViewById(R.id.navHome), findViewById(R.id.navHomeIcon), findViewById(R.id.navHomeLabel),
                BottomTab.HOME, { HomeFuncionarioFragment() }
            ),
            NavItem(
                findViewById(R.id.navModules), findViewById(R.id.navModulesIcon), findViewById(R.id.navModulesLabel),
                BottomTab.MODULES, { ModulesFragment() }
            ),
            NavItem(
                findViewById(R.id.navChat), findViewById(R.id.navChatIcon), findViewById(R.id.navChatLabel),
                BottomTab.CHAT, { ChatFragment() }
            ),
            NavItem(
                findViewById(R.id.navVacation), findViewById(R.id.navVacationIcon), findViewById(R.id.navVacationLabel),
                BottomTab.VACATION, { RequestsFragment() }
            ),
            NavItem(
                findViewById(R.id.navAttendance), findViewById(R.id.navAttendanceIcon), findViewById(R.id.navAttendanceLabel),
                BottomTab.ATTENDANCE, { HistoryFragment() }
            ),
            NavItem(
                findViewById(R.id.navProfile), findViewById(R.id.navProfileIcon), findViewById(R.id.navProfileLabel),
                BottomTab.PROFILE, { ProfileFragment() }
            ),
        )

        items.forEach { item ->
            item.container.setOnClickListener {
                selectTab(item.tab)
            }
        }

        this.navItems = items
    }

    private lateinit var navItems: List<NavItem>

    private fun selectTab(tab: BottomTab) {
        if (activeTab == tab) return
        activeTab = tab

        navItems.forEach { item ->
            val color = getColor(if (item.tab == tab) R.color.brand_accent else R.color.text_muted)
            item.icon.setColorFilter(color)
            item.label.setTextColor(color)
        }

        val target = navItems.first { it.tab == tab }
        supportFragmentManager.popBackStack(null, androidx.fragment.app.FragmentManager.POP_BACK_STACK_INCLUSIVE)
        loadFragment(target.fragment())
    }

    private fun setupGestorBottomNav() {
        val items = listOf(
            GestorNavItem(
                findViewById(R.id.navGestorDashboard), findViewById(R.id.navGestorDashboardIcon), findViewById(R.id.navGestorDashboardLabel),
                GestorTab.DASHBOARD, { DashboardGestorFragment() }
            ),
            GestorNavItem(
                findViewById(R.id.navGestorEquipa), findViewById(R.id.navGestorEquipaIcon), findViewById(R.id.navGestorEquipaLabel),
                GestorTab.EQUIPA, { EquipaGestorFragment() }
            ),
            GestorNavItem(
                findViewById(R.id.navGestorFerias), findViewById(R.id.navGestorFeriasIcon), findViewById(R.id.navGestorFeriasLabel),
                GestorTab.FERIAS, { PedidosFeriasFragment() }
            ),
            GestorNavItem(
                findViewById(R.id.navGestorRelatorios), findViewById(R.id.navGestorRelatoriosIcon), findViewById(R.id.navGestorRelatoriosLabel),
                GestorTab.RELATORIOS, { RelatoriosGestorFragment() }
            ),
            GestorNavItem(
                findViewById(R.id.navGestorMais), findViewById(R.id.navGestorMaisIcon), findViewById(R.id.navGestorMaisLabel),
                GestorTab.MAIS, { MaisFragment() }
            ),
        )

        items.forEach { item ->
            item.container.setOnClickListener {
                selectGestorTab(item.tab)
            }
        }

        this.gestorNavItems = items
    }

    private lateinit var gestorNavItems: List<GestorNavItem>

    private fun selectGestorTab(tab: GestorTab) {
        if (activeGestorTab == tab) return
        activeGestorTab = tab

        gestorNavItems.forEach { item ->
            val color = getColor(if (item.tab == tab) R.color.brand_accent else R.color.text_muted)
            item.icon.setColorFilter(color)
            item.label.setTextColor(color)
        }

        val target = gestorNavItems.first { it.tab == tab }
        supportFragmentManager.popBackStack(null, androidx.fragment.app.FragmentManager.POP_BACK_STACK_INCLUSIVE)
        loadFragment(target.fragment())
    }

    private fun loadFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .commit()
    }

    /** Empurra um ecrã secundário (ex.: detalhe de funcionário, a partir da
     * Equipa) para cima da tab actual, mantendo-a no back stack — ao
     * contrário de [loadFragment], usado só para trocar de tab. */
    fun pushFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .addToBackStack(null)
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
