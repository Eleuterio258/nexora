package tech.e258tech.nexora_mobile.ui.screens.main

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.coordinatorlayout.widget.CoordinatorLayout
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.widget.NestedScrollView
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.databinding.PartialAppbarBinding
import tech.e258tech.nexora_mobile.databinding.PartialBottomNavBinding
import tech.e258tech.nexora_mobile.ui.screens.attendance.AttendanceActivity
import tech.e258tech.nexora_mobile.ui.screens.chat.ChatActivity
import tech.e258tech.nexora_mobile.ui.screens.modules.ModulesActivity
import tech.e258tech.nexora_mobile.ui.screens.profile.ProfileActivity
import tech.e258tech.nexora_mobile.ui.screens.vacation.VacationActivity
import tech.e258tech.nexora_mobile.ui.tabs.dp

enum class InternalPage {
    HOME, MODULES, CHAT, VACATION, ATTENDANCE, PROFILE
}

/** Views comuns a todos os separadores, extraídas do layout próprio de cada Activity. */
class TabViews(
    val root: CoordinatorLayout,
    val appBarLayout: PartialAppbarBinding,
    val bottomNav: PartialBottomNavBinding,
    val dashboardScroll: NestedScrollView,
    val mainContent: LinearLayout,
)

/**
 * Ecrã base partilhado pelos separadores da barra inferior (Início, Módulos, Chat,
 * Férias, Assiduidade, Perfil). Cada separador é a sua própria Activity, com o seu
 * próprio layout XML — mas todos incluem o mesmo appbar/bottomNav e usam o mesmo
 * mecanismo de navegação.
 */
abstract class BaseTabActivity : AppCompatActivity() {

    lateinit var binding: TabViews
        private set

    internal var currentBottomInset = 0

    protected abstract val page: InternalPage

    protected abstract fun inflateViews(): TabViews

    protected abstract fun renderContent()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = inflateViews()
        setContentView(binding.root)

        setupSystemBars()
        setupNavigation()
        renderContent()
    }

    private fun setupSystemBars() {
        window.statusBarColor = getColor(R.color.primary_blue)
        window.navigationBarColor = getColor(R.color.white)

        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = true
        }

        val appBar = binding.appBarLayout.root
        val nav = binding.bottomNav.root

        val baseAppBarTopPadding = appBar.paddingTop
        val baseNavPaddingTop = nav.paddingTop
        val baseNavPaddingBottom = nav.paddingBottom

        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            currentBottomInset = systemBars.bottom

            appBar.setPadding(
                appBar.paddingLeft,
                baseAppBarTopPadding + systemBars.top,
                appBar.paddingRight,
                appBar.paddingBottom,
            )

            nav.setPadding(
                nav.paddingLeft,
                baseNavPaddingTop,
                nav.paddingRight,
                baseNavPaddingBottom + systemBars.bottom,
            )

            binding.mainContent.setPadding(
                binding.mainContent.paddingLeft,
                binding.mainContent.paddingTop,
                binding.mainContent.paddingRight,
                dp(78) + systemBars.bottom,
            )

            insets
        }
        ViewCompat.requestApplyInsets(binding.root)
    }

    private fun setupNavigation() {
        val nav = binding.bottomNav
        val items = listOf(
            InternalNavItem(nav.navHome, nav.navHomeIcon, nav.navHomeLabel, InternalPage.HOME, MainActivity::class.java),
            InternalNavItem(nav.navModules, nav.navModulesIcon, nav.navModulesLabel, InternalPage.MODULES, ModulesActivity::class.java),
            InternalNavItem(nav.navChat, nav.navChatIcon, nav.navChatLabel, InternalPage.CHAT, ChatActivity::class.java),
            InternalNavItem(nav.navVacation, nav.navVacationIcon, nav.navVacationLabel, InternalPage.VACATION, VacationActivity::class.java),
            InternalNavItem(nav.navAttendance, nav.navAttendanceIcon, nav.navAttendanceLabel, InternalPage.ATTENDANCE, AttendanceActivity::class.java),
            InternalNavItem(nav.navProfile, nav.navProfileIcon, nav.navProfileLabel, InternalPage.PROFILE, ProfileActivity::class.java),
        )

        items.forEach { item ->
            val color = getColor(if (item.page == page) R.color.primary_blue else R.color.text_hint)
            item.icon.setColorFilter(color)
            item.label.setTextColor(color)

            item.container.setOnClickListener {
                if (item.page != page) navigateTo(item.activityClass)
            }
        }
    }

    private fun navigateTo(target: Class<out BaseTabActivity>) {
        startActivity(Intent(this, target))
        overridePendingTransition(0, 0)
        finish()
    }

    internal fun setBottomNavigationVisible(visible: Boolean) {
        binding.bottomNav.root.visibility = if (visible) View.VISIBLE else View.GONE
    }

    private data class InternalNavItem(
        val container: LinearLayout,
        val icon: ImageView,
        val label: TextView,
        val page: InternalPage,
        val activityClass: Class<out BaseTabActivity>,
    )
}
