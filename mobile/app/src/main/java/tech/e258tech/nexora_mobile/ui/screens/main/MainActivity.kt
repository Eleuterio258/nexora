package tech.e258tech.nexora_mobile.ui.screens.main

import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.app
import tech.e258tech.nexora_mobile.databinding.ActivityMainBinding
import tech.e258tech.nexora_mobile.ui.tabs.AttendanceTab
import tech.e258tech.nexora_mobile.ui.tabs.ChatTab
import tech.e258tech.nexora_mobile.ui.tabs.HomeTab
import tech.e258tech.nexora_mobile.ui.tabs.ModulesTab
import tech.e258tech.nexora_mobile.ui.tabs.ProfileTab
import tech.e258tech.nexora_mobile.ui.tabs.VacationTab
import tech.e258tech.nexora_mobile.ui.tabs.dp

class MainActivity : AppCompatActivity() {

    internal lateinit var binding: ActivityMainBinding
    internal lateinit var homeViews: List<View>
    internal var currentBottomInset = 0

    private val homeTab by lazy { HomeTab(this) }
    private val modulesTab by lazy { ModulesTab(this) }
    private val chatTab by lazy { ChatTab(this) }
    private val vacationTab by lazy { VacationTab(this) }
    private val attendanceTab by lazy { AttendanceTab(this) }
    private val profileTab by lazy { ProfileTab(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupSystemBars()
        loadUserName()
        homeTab.setupDashboard()
        homeViews = (0 until binding.mainContent.childCount).map { binding.mainContent.getChildAt(it) }
        setupNavigation()
        setupBackPress()
    }

    private fun loadUserName() {
        lifecycleScope.launch {
            val nome = app.authRepository.getUserNome()
            binding.tvUserName.text = nome.ifEmpty { "" }
        }
    }

    private fun setupBackPress() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (chatTab.handleBack()) return
                isEnabled = false
                onBackPressedDispatcher.onBackPressed()
                isEnabled = true
            }
        })
    }

    private fun setupSystemBars() {
        window.statusBarColor = getColor(R.color.primary_blue)
        window.navigationBarColor = getColor(R.color.white)

        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = true
        }

        val baseAppBarTopPadding = binding.appBarLayout.paddingTop
        val baseNavPaddingTop = binding.bottomNav.paddingTop
        val baseNavPaddingBottom = binding.bottomNav.paddingBottom

        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            currentBottomInset = systemBars.bottom

            binding.appBarLayout.setPadding(
                binding.appBarLayout.paddingLeft,
                baseAppBarTopPadding + systemBars.top,
                binding.appBarLayout.paddingRight,
                binding.appBarLayout.paddingBottom,
            )

            binding.bottomNav.setPadding(
                binding.bottomNav.paddingLeft,
                baseNavPaddingTop,
                binding.bottomNav.paddingRight,
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
        val items = listOf(
            InternalNavItem(binding.navHome, binding.navHomeIcon, binding.navHomeLabel, InternalPage.HOME),
            InternalNavItem(binding.navModules, binding.navModulesIcon, binding.navModulesLabel, InternalPage.MODULES),
            InternalNavItem(binding.navChat, binding.navChatIcon, binding.navChatLabel, InternalPage.CHAT),
            InternalNavItem(binding.navVacation, binding.navVacationIcon, binding.navVacationLabel, InternalPage.VACATION),
            InternalNavItem(binding.navAttendance, binding.navAttendanceIcon, binding.navAttendanceLabel, InternalPage.ATTENDANCE),
            InternalNavItem(binding.navProfile, binding.navProfileIcon, binding.navProfileLabel, InternalPage.PROFILE),
        )

        fun selectItem(selected: InternalNavItem) {
            items.forEach { item ->
                val color = getColor(if (item == selected) R.color.primary_blue else R.color.text_hint)
                item.icon.setColorFilter(color)
                item.label.setTextColor(color)
            }
        }

        items.forEach { item ->
            item.container.setOnClickListener {
                selectItem(item)
                showPage(item.page)
            }
        }

        selectItem(items.first())
        showPage(InternalPage.HOME)
    }

    private fun showPage(page: InternalPage) {
        if (page != InternalPage.CHAT) {
            chatTab.leave()
            setBottomNavigationVisible(true)
        }

        when (page) {
            InternalPage.HOME -> homeTab.show()
            InternalPage.MODULES -> modulesTab.show()
            InternalPage.CHAT -> chatTab.show()
            InternalPage.VACATION -> vacationTab.show()
            InternalPage.ATTENDANCE -> attendanceTab.show()
            InternalPage.PROFILE -> profileTab.show()
        }
    }

    internal fun setBottomNavigationVisible(visible: Boolean) {
        binding.bottomNav.visibility = if (visible) View.VISIBLE else View.GONE
    }

    private enum class InternalPage {
        HOME, MODULES, CHAT, VACATION, ATTENDANCE, PROFILE
    }

    private data class InternalNavItem(
        val container: LinearLayout,
        val icon: ImageView,
        val label: TextView,
        val page: InternalPage,
    )
}
