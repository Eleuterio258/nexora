package tech.e258tech.nexora_mobile.ui.tabs

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.Toast
import androidx.coordinatorlayout.widget.CoordinatorLayout
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.appbar.AppBarLayout
import kotlinx.coroutines.launch
import tech.e258tech.nexora_mobile.R
import tech.e258tech.nexora_mobile.app
import tech.e258tech.nexora_mobile.data.model.Conversa
import tech.e258tech.nexora_mobile.data.model.Mensagem
import tech.e258tech.nexora_mobile.data.model.WsMensagemRecebida
import tech.e258tech.nexora_mobile.data.repository.ChatRepository
import tech.e258tech.nexora_mobile.ui.screens.main.BaseTabActivity
import tech.e258tech.nexora_mobile.utils.Result

internal class ChatTab(private val activity: BaseTabActivity) {

    private var activeContact: ChatContact? = null
    private var inputBar: LinearLayout? = null
    private var headerView: LinearLayout? = null
    private var socketStarted = false
    private var socketConnected = false
    private var currentUserId = 0L
    private var contacts: List<ChatContact> = emptyList()
    private val messagesByConversation = mutableMapOf<Long, List<ChatMsg>>()

    fun show() {
        activeContact = null
        hideInputBar()
        restoreNormalHeader()
        activity.setBottomNavigationVisible(true)
        ensureSocket()
        renderContacts()
        loadConversations()
    }

    fun leave() {
        activeContact?.id?.let { activity.app.chatRepository.leaveRoom(it) }
        activeContact = null
        hideInputBar()
        restoreNormalHeader()
    }

    fun handleBack(): Boolean {
        if (activeContact == null) return false
        show()
        return true
    }

    private fun loadConversations() {
        activity.lifecycleScope.launch {
            when (val result = activity.app.chatRepository.listarConversas()) {
                is Result.Success -> {
                    contacts = result.data.map { it.toContact() }
                    if (activeContact == null) renderContacts()
                }
                is Result.Error -> {
                    if (contacts.isEmpty()) renderMessage("Nao foi possivel carregar as conversas.")
                    else Toast.makeText(activity, result.message, Toast.LENGTH_SHORT).show()
                }
                Result.Loading -> Unit
            }
        }
    }

    private fun ensureSocket() {
        if (socketStarted) return
        socketStarted = true

        activity.lifecycleScope.launch {
            currentUserId = activity.app.tokenManager.getUserId()
            val token = activity.app.tokenManager.getAccessToken()
            if (!token.isNullOrBlank()) {
                activity.app.chatRepository.connect(token)
            }
        }

        activity.lifecycleScope.launch {
            activity.app.chatRepository.wsEvents.collect { event ->
                when (event) {
                    is ChatRepository.WsEvent.Connected -> {
                        socketConnected = true
                        activeContact?.id?.let { activity.app.chatRepository.joinRoom(it) }
                    }
                    is ChatRepository.WsEvent.MessageReceived -> handleSocketMessage(event.msg)
                    is ChatRepository.WsEvent.Disconnected -> socketConnected = false
                    is ChatRepository.WsEvent.Error -> socketConnected = false
                    else -> Unit
                }
            }
        }
    }

    private fun handleSocketMessage(message: WsMensagemRecebida) {
        val chatMsg = ChatMsg(
            text = message.conteudo,
            isMe = message.autorId == currentUserId,
            time = formatTime(message.criadoEm),
        )
        val current = messagesByConversation[message.conversaId].orEmpty()
        messagesByConversation[message.conversaId] = current + chatMsg
        if (activeContact?.id == message.conversaId) {
            showDetail(activeContact ?: return)
        }
        loadConversations()
    }

    private fun renderContacts() = with(activity.binding.mainContent) {
        removeAllViews()
        setPadding(0, 0, 0, activity.dp(78) + activity.currentBottomInset)
        addView(buildListHeader())

        if (contacts.isEmpty()) {
            renderMessage("Ainda nao existem conversas.")
            return@with
        }

        contacts.forEachIndexed { index, contact ->
            addView(buildConversationItem(contact))
            if (index < contacts.lastIndex) {
                addView(View(activity).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        activity.dp(1),
                    ).apply { marginStart = activity.dp(76) }
                    setBackgroundColor(activity.getColor(R.color.border_color))
                })
            }
        }
    }

    private fun buildListHeader(): View =
        LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(activity.dp(20), activity.dp(20), activity.dp(20), activity.dp(16))

            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                addView(activity.textView("Mensagens", 22f, R.color.text_primary, bold = true))
                val unread = contacts.sumOf { it.unread }
                addView(activity.textView(
                    if (unread > 0) "$unread novas mensagens" else "Todas as mensagens",
                    13f,
                    R.color.text_secondary,
                ).apply { setPadding(0, activity.dp(3), 0, 0) })
            })

            addView(ImageView(context).apply {
                setImageResource(android.R.drawable.ic_menu_search)
                setColorFilter(activity.getColor(R.color.primary_blue))
                layoutParams = LinearLayout.LayoutParams(activity.dp(40), activity.dp(40))
                background = activity.oval(activity.getColor(R.color.background))
                setPadding(activity.dp(8), activity.dp(8), activity.dp(8), activity.dp(8))
            })
        }

    private fun buildConversationItem(contact: ChatContact): View {
        val rippleValue = TypedValue()
        activity.theme.resolveAttribute(android.R.attr.selectableItemBackground, rippleValue, true)

        return LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(activity.dp(16), activity.dp(14), activity.dp(16), activity.dp(14))
            background = ContextCompat.getDrawable(context, rippleValue.resourceId)

            addView(FrameLayout(context).apply {
                layoutParams = LinearLayout.LayoutParams(activity.dp(52), activity.dp(52))
                addView(activity.textView(contact.initials, 15f, R.color.white, bold = true).apply {
                    gravity = Gravity.CENTER
                    layoutParams = FrameLayout.LayoutParams(activity.dp(48), activity.dp(48)).apply {
                        gravity = Gravity.CENTER
                    }
                    background = activity.oval(contact.color)
                })
            })

            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                    setMargins(activity.dp(12), 0, activity.dp(8), 0)
                }
                addView(activity.textView(contact.name, 15f, R.color.text_primary, bold = true))
                addView(activity.textView(contact.lastMessage, 13f, R.color.text_secondary).apply {
                    setPadding(0, activity.dp(3), 0, 0)
                    maxLines = 1
                    ellipsize = TextUtils.TruncateAt.END
                })
            })

            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.END
                layoutParams = LinearLayout.LayoutParams(activity.dp(52), ViewGroup.LayoutParams.WRAP_CONTENT)
                addView(activity.textView(contact.time, 11f, R.color.text_hint).apply { gravity = Gravity.END })
                if (contact.unread > 0) {
                    addView(activity.textView(contact.unread.toString(), 11f, R.color.white, bold = true).apply {
                        gravity = Gravity.CENTER
                        includeFontPadding = false
                        layoutParams = LinearLayout.LayoutParams(activity.dp(20), activity.dp(20)).apply {
                            topMargin = activity.dp(5)
                            gravity = Gravity.END
                        }
                        background = activity.oval(activity.getColor(R.color.primary_blue))
                    })
                }
            })

            setOnClickListener { showDetail(contact) }
        }
    }

    private fun showDetail(contact: ChatContact) {
        activeContact?.id?.takeIf { it != contact.id }?.let { activity.app.chatRepository.leaveRoom(it) }
        activeContact = contact
        activity.setBottomNavigationVisible(false)
        setupHeader(contact)
        ensureSocket()
        if (socketConnected) activity.app.chatRepository.joinRoom(contact.id)

        activity.binding.mainContent.removeAllViews()
        activity.binding.mainContent.setPadding(0, 0, 0, activity.dp(80) + activity.currentBottomInset)
        activity.binding.mainContent.addView(buildDateSeparator("Hoje"))

        val messages = messagesByConversation[contact.id].orEmpty()
        messages.forEach { activity.binding.mainContent.addView(buildBubble(it, contact)) }
        if (messages.isEmpty()) renderMessage("A carregar mensagens...")

        showInputBar()
        if (!messagesByConversation.containsKey(contact.id)) loadMessages(contact)
        activity.binding.dashboardScroll.post { activity.binding.dashboardScroll.fullScroll(View.FOCUS_DOWN) }
    }

    private fun loadMessages(contact: ChatContact) {
        activity.lifecycleScope.launch {
            when (val result = activity.app.chatRepository.listarMensagens(contact.id)) {
                is Result.Success -> {
                    val userId = activity.app.tokenManager.getUserId()
                    messagesByConversation[contact.id] = result.data.map { it.toChatMsg(userId) }
                    if (activeContact?.id == contact.id) showDetail(contact)
                }
                is Result.Error -> Toast.makeText(activity, result.message, Toast.LENGTH_SHORT).show()
                Result.Loading -> Unit
            }
        }
    }

    private fun showInputBar() {
        hideInputBar()

        val editText = EditText(activity).apply {
            hint = "Escrever mensagem..."
            setHintTextColor(activity.getColor(R.color.text_hint))
            setTextColor(activity.getColor(R.color.text_primary))
            textSize = 14f
            maxLines = 3
            background = GradientDrawable().apply {
                setColor(activity.getColor(R.color.background))
                cornerRadius = activity.dp(24).toFloat()
                setStroke(activity.dp(1), activity.getColor(R.color.border_color))
            }
            setPadding(activity.dp(16), activity.dp(10), activity.dp(16), activity.dp(10))
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginEnd = activity.dp(10)
            }
        }

        val bar = LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(activity.dp(12), activity.dp(10), activity.dp(12), activity.dp(10))
            setBackgroundColor(Color.WHITE)
            elevation = activity.dp(12).toFloat()

            addView(editText)
            addView(ImageView(context).apply {
                setImageResource(R.drawable.ic_send)
                layoutParams = LinearLayout.LayoutParams(activity.dp(46), activity.dp(46))
                background = activity.oval(activity.getColor(R.color.primary_blue))
                setPadding(activity.dp(11), activity.dp(11), activity.dp(11), activity.dp(11))
                setOnClickListener {
                    val contact = activeContact ?: return@setOnClickListener
                    val text = editText.text.toString().trim()
                    if (text.isEmpty()) return@setOnClickListener
                    editText.setText("")
                    sendMessage(contact, text)
                }
            })
        }

        inputBar = bar
        activity.binding.root.addView(bar, CoordinatorLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply {
            gravity = Gravity.BOTTOM
            bottomMargin = activity.currentBottomInset
        })
    }

    private fun sendMessage(contact: ChatContact, text: String) {
        if (socketConnected) {
            activity.app.chatRepository.sendMessage(contact.id, text)
            return
        }

        val current = messagesByConversation[contact.id].orEmpty()
        messagesByConversation[contact.id] = current + ChatMsg(text, true, "")
        showDetail(contact)

        activity.lifecycleScope.launch {
            when (val result = activity.app.chatRepository.enviarMensagem(contact.id, text)) {
                is Result.Success -> {
                    messagesByConversation.remove(contact.id)
                    loadMessages(contact)
                }
                is Result.Error -> {
                    messagesByConversation[contact.id] = current
                    showDetail(contact)
                    Toast.makeText(activity, result.message, Toast.LENGTH_SHORT).show()
                }
                Result.Loading -> Unit
            }
        }
    }

    private fun buildDateSeparator(label: String): View =
        LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(activity.dp(20), activity.dp(16), activity.dp(20), activity.dp(8))
            addView(activity.textView(label, 11f, R.color.text_hint).apply {
                gravity = Gravity.CENTER
                setPadding(activity.dp(12), activity.dp(5), activity.dp(12), activity.dp(5))
                layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
            })
        }

    private fun buildBubble(msg: ChatMsg, contact: ChatContact): View =
        LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { setMargins(activity.dp(12), activity.dp(3), activity.dp(12), activity.dp(3)) }

            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = if (msg.isMe) Gravity.END else Gravity.START

                if (!msg.isMe) {
                    addView(activity.textView(contact.initials, 10f, R.color.white, bold = true).apply {
                        gravity = Gravity.CENTER
                        layoutParams = LinearLayout.LayoutParams(activity.dp(28), activity.dp(28)).apply {
                            marginEnd = activity.dp(6)
                            gravity = Gravity.BOTTOM
                        }
                        background = activity.oval(contact.color)
                    })
                }

                addView(LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = if (msg.isMe) Gravity.END else Gravity.START
                    addView(activity.textView(msg.text, 14f, if (msg.isMe) R.color.white else R.color.text_primary).apply {
                        setPadding(activity.dp(12), activity.dp(8), activity.dp(12), activity.dp(8))
                        maxWidth = (activity.resources.displayMetrics.widthPixels * 0.70).toInt()
                        background = GradientDrawable().apply {
                            setColor(if (msg.isMe) activity.getColor(R.color.primary_blue) else Color.WHITE)
                            cornerRadius = activity.dp(16).toFloat()
                            if (!msg.isMe) setStroke(activity.dp(1), activity.getColor(R.color.border_color))
                        }
                    })
                    addView(activity.textView(msg.time, 10f, R.color.text_hint).apply {
                        setPadding(activity.dp(4), activity.dp(3), activity.dp(4), 0)
                        gravity = if (msg.isMe) Gravity.END else Gravity.START
                    })
                })
            })
        }

    private fun setupHeader(contact: ChatContact) {
        removeHeader()
        activity.binding.appBarLayout.normalHeader.visibility = View.GONE

        val rippleValue = TypedValue()
        activity.theme.resolveAttribute(android.R.attr.selectableItemBackgroundBorderless, rippleValue, true)

        val header = LinearLayout(activity).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(activity.dp(4), 0, activity.dp(12), 0)
            layoutParams = AppBarLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                activity.dp(64),
            )

            addView(ImageView(context).apply {
                setImageResource(R.drawable.ic_arrow_back)
                layoutParams = LinearLayout.LayoutParams(activity.dp(48), activity.dp(48))
                background = ContextCompat.getDrawable(context, rippleValue.resourceId)
                setPadding(activity.dp(12), activity.dp(12), activity.dp(12), activity.dp(12))
                setOnClickListener { show() }
            })

            addView(activity.textView(contact.initials, 13f, R.color.white, bold = true).apply {
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(activity.dp(38), activity.dp(38)).apply {
                    marginStart = activity.dp(2)
                    marginEnd = activity.dp(10)
                }
                background = activity.oval(contact.color)
            })

            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                addView(activity.textView(contact.name, 16f, R.color.white, bold = true))
                addView(activity.textView("Online", 11f, R.color.white).apply {
                    alpha = 0.75f
                    setPadding(0, activity.dp(2), 0, 0)
                })
            })
        }

        activity.binding.appBarLayout.root.addView(header)
        headerView = header
    }

    private fun hideInputBar() {
        inputBar?.let { activity.binding.root.removeView(it) }
        inputBar = null
    }

    private fun removeHeader() {
        headerView?.let { activity.binding.appBarLayout.root.removeView(it) }
        headerView = null
    }

    private fun restoreNormalHeader() {
        removeHeader()
        activity.binding.appBarLayout.normalHeader.visibility = View.VISIBLE
    }

    private fun renderMessage(message: String) {
        activity.binding.mainContent.addView(activity.textView(message, 14f, R.color.text_secondary).apply {
            gravity = Gravity.CENTER
            setPadding(activity.dp(20), activity.dp(40), activity.dp(20), activity.dp(40))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
        })
    }

    private fun Conversa.toContact(): ChatContact {
        val displayName = nome?.takeIf { it.isNotBlank() } ?: "Conversa #$id"
        return ChatContact(
            id = id,
            initials = initialsFor(displayName),
            name = displayName,
            lastMessage = ultimaMensagem ?: "Sem mensagens",
            time = formatTime(ultimaData),
            unread = naoLidas,
            color = colorForId(id),
        )
    }

    private fun Mensagem.toChatMsg(currentUserId: Long): ChatMsg =
        ChatMsg(
            text = conteudo,
            isMe = autorId != null && autorId == currentUserId,
            time = formatTime(criadoEm),
        )

    private fun initialsFor(name: String): String =
        name.split(" ")
            .filter { it.isNotBlank() }
            .take(2)
            .joinToString("") { it.first().uppercaseChar().toString() }
            .ifBlank { "CH" }

    private fun colorForId(id: Long): Int {
        val colors = intArrayOf(
            0xFF10B981.toInt(),
            0xFF7C3AED.toInt(),
            0xFF059669.toInt(),
            0xFFD97706.toInt(),
            0xFF2563EB.toInt(),
        )
        return colors[(id % colors.size).toInt()]
    }

    private fun formatTime(value: String?): String {
        if (value.isNullOrBlank()) return ""
        val timeStart = value.indexOf('T')
        return if (timeStart >= 0 && value.length >= timeStart + 6) {
            value.substring(timeStart + 1, timeStart + 6)
        } else {
            value.take(10)
        }
    }

    private data class ChatContact(
        val id: Long,
        val initials: String,
        val name: String,
        val lastMessage: String,
        val time: String,
        val unread: Int,
        val color: Int,
    )

    private data class ChatMsg(val text: String, val isMe: Boolean, val time: String)
}
