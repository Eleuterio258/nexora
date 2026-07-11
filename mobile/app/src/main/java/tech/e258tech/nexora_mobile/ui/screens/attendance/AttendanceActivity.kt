package tech.e258tech.nexora_mobile.ui.screens.attendance

import tech.e258tech.nexora_mobile.databinding.ActivityAttendanceBinding
import tech.e258tech.nexora_mobile.ui.screens.main.BaseTabActivity
import tech.e258tech.nexora_mobile.ui.screens.main.InternalPage
import tech.e258tech.nexora_mobile.ui.screens.main.TabViews
import tech.e258tech.nexora_mobile.ui.tabs.AttendanceTab

class AttendanceActivity : BaseTabActivity() {

    override val page = InternalPage.ATTENDANCE

    private val attendanceTab by lazy { AttendanceTab(this) }

    override fun inflateViews(): TabViews {
        val b = ActivityAttendanceBinding.inflate(layoutInflater)
        return TabViews(b.root, b.appBarLayout, b.bottomNav, b.dashboardScroll, b.mainContent)
    }

    override fun renderContent() = attendanceTab.show()
}
