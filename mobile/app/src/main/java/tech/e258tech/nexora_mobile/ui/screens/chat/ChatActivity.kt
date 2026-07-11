package tech.e258tech.nexora_mobile.ui.screens.chat

import android.os.Bundle
import androidx.activity.OnBackPressedCallback
import tech.e258tech.nexora_mobile.databinding.ActivityChatBinding
import tech.e258tech.nexora_mobile.ui.screens.main.BaseTabActivity
import tech.e258tech.nexora_mobile.ui.screens.main.InternalPage
import tech.e258tech.nexora_mobile.ui.screens.main.TabViews
import tech.e258tech.nexora_mobile.ui.tabs.ChatTab

class ChatActivity : BaseTabActivity() {

    override val page = InternalPage.CHAT

    private val chatTab by lazy { ChatTab(this) }

    override fun inflateViews(): TabViews {
        val b = ActivityChatBinding.inflate(layoutInflater)
        return TabViews(b.root, b.appBarLayout, b.bottomNav, b.dashboardScroll, b.mainContent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (chatTab.handleBack()) return
                isEnabled = false
                onBackPressedDispatcher.onBackPressed()
                isEnabled = true
            }
        })
    }

    override fun renderContent() = chatTab.show()

    override fun onDestroy() {
        chatTab.leave()
        super.onDestroy()
    }
}
