package tech.e258tech.nexora_mobile.ui.screens.main

import tech.e258tech.nexora_mobile.databinding.ActivityMainBinding
import tech.e258tech.nexora_mobile.ui.tabs.HomeTab

class MainActivity : BaseTabActivity() {

    override val page = InternalPage.HOME

    private val homeTab by lazy { HomeTab(this) }

    override fun inflateViews(): TabViews {
        val b = ActivityMainBinding.inflate(layoutInflater)
        return TabViews(b.root, b.appBarLayout, b.bottomNav, b.dashboardScroll, b.mainContent)
    }

    override fun renderContent() = homeTab.show()
}
