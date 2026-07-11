package tech.e258tech.nexora_mobile.ui.screens.vacation

import tech.e258tech.nexora_mobile.databinding.ActivityVacationBinding
import tech.e258tech.nexora_mobile.ui.screens.main.BaseTabActivity
import tech.e258tech.nexora_mobile.ui.screens.main.InternalPage
import tech.e258tech.nexora_mobile.ui.screens.main.TabViews
import tech.e258tech.nexora_mobile.ui.tabs.VacationTab

class VacationActivity : BaseTabActivity() {

    override val page = InternalPage.VACATION

    private val vacationTab by lazy { VacationTab(this) }

    override fun inflateViews(): TabViews {
        val b = ActivityVacationBinding.inflate(layoutInflater)
        return TabViews(b.root, b.appBarLayout, b.bottomNav, b.dashboardScroll, b.mainContent)
    }

    override fun renderContent() = vacationTab.show()
}
