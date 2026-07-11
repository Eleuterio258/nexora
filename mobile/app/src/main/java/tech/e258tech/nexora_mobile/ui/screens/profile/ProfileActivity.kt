package tech.e258tech.nexora_mobile.ui.screens.profile

import tech.e258tech.nexora_mobile.databinding.ActivityProfileBinding
import tech.e258tech.nexora_mobile.ui.screens.main.BaseTabActivity
import tech.e258tech.nexora_mobile.ui.screens.main.InternalPage
import tech.e258tech.nexora_mobile.ui.screens.main.TabViews
import tech.e258tech.nexora_mobile.ui.tabs.ProfileTab

class ProfileActivity : BaseTabActivity() {

    override val page = InternalPage.PROFILE

    private val profileTab by lazy { ProfileTab(this) }

    override fun inflateViews(): TabViews {
        val b = ActivityProfileBinding.inflate(layoutInflater)
        return TabViews(b.root, b.appBarLayout, b.bottomNav, b.dashboardScroll, b.mainContent)
    }

    override fun renderContent() = profileTab.show()
}
