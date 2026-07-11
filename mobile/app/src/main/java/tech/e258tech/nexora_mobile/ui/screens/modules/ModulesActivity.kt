package tech.e258tech.nexora_mobile.ui.screens.modules

import tech.e258tech.nexora_mobile.databinding.ActivityModulesBinding
import tech.e258tech.nexora_mobile.ui.screens.main.BaseTabActivity
import tech.e258tech.nexora_mobile.ui.screens.main.InternalPage
import tech.e258tech.nexora_mobile.ui.screens.main.TabViews
import tech.e258tech.nexora_mobile.ui.tabs.ModulesTab

class ModulesActivity : BaseTabActivity() {

    override val page = InternalPage.MODULES

    private val modulesTab by lazy { ModulesTab(this) }

    override fun inflateViews(): TabViews {
        val b = ActivityModulesBinding.inflate(layoutInflater)
        return TabViews(b.root, b.appBarLayout, b.bottomNav, b.dashboardScroll, b.mainContent)
    }

    override fun renderContent() = modulesTab.show()
}
