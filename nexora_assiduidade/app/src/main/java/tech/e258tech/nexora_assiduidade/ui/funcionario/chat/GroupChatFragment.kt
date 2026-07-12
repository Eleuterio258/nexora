package tech.e258tech.nexora_assiduidade.ui.funcionario.chat

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ChatMessage
import tech.e258tech.nexora_assiduidade.data.model.ChatMessageRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.data.network.ws.ChatWebSocketService
import tech.e258tech.nexora_assiduidade.ui.funcionario.chat.adapter.ChatMessageAdapter
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de Chat em Grupo
 * Conversa em grupo com múltiplos participantes via WebSocket nativo.
 */
class GroupChatFragment : Fragment() {

    companion object {
        private const val ARG_CHAT_ID = "chat_id"
        private const val ARG_CHAT_TITLE = "chat_title"

        fun newInstance(chatId: Long, title: String? = null): GroupChatFragment {
            return GroupChatFragment().apply {
                arguments = Bundle().apply {
                    putLong(ARG_CHAT_ID, chatId)
                    putString(ARG_CHAT_TITLE, title)
                }
            }
        }
    }

    private lateinit var sessionManager: SessionManager
    private lateinit var adapter: ChatMessageAdapter
    private val messages = mutableListOf<ChatMessage>()

    private var chatId: Long = 0
    private var chatTitle: String? = null
    private var currentUserId: Long = 0
    private val pendingLocalIds = mutableMapOf<String, ChatMessage>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        chatId = arguments?.getLong(ARG_CHAT_ID) ?: 0
        chatTitle = arguments?.getString(ARG_CHAT_TITLE)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_group_chat, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        currentUserId = sessionManager.getUserId()?.toLongOrNull() ?: 0L

        if (currentUserId == 0L) {
            Toast.makeText(context, "Sessão inválida", Toast.LENGTH_SHORT).show()
            return
        }

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewGroupMessages)
        val etMessage = view.findViewById<EditText>(R.id.etGroupMessage)
        val btnSend = view.findViewById<Button>(R.id.btnSendGroup)
        val progressBar = view.findViewById<ProgressBar?>(R.id.progressBarGroup)
        val tvStatus = view.findViewById<TextView?>(R.id.tvConnectionStatusGroup)

        view.findViewById<TextView?>(R.id.tvChatTitle)?.text = chatTitle ?: "Chat em Grupo"

        adapter = ChatMessageAdapter(currentUserId.toString())
        recyclerView.layoutManager = LinearLayoutManager(context).apply {
            stackFromEnd = true
        }
        recyclerView.adapter = adapter

        setupWebSocketListeners(tvStatus)
        ChatWebSocketService.connect(requireContext())

        if (chatId != 0L) {
            ChatWebSocketService.joinChat(chatId)
            loadMessages(chatId, progressBar)
        } else {
            Toast.makeText(context, "Grupo não especificado", Toast.LENGTH_SHORT).show()
        }

        btnSend.setOnClickListener {
            val message = etMessage.text.toString().trim()
            if (message.isNotEmpty()) {
                sendMessage(message)
                etMessage.text?.clear()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        if (chatId != 0L) {
            ChatWebSocketService.leaveChat(chatId)
        }
        ChatWebSocketService.setOnMessageReceived {}
        ChatWebSocketService.setOnMessageDelivered { _, _ -> }
        ChatWebSocketService.setOnConnected {}
        ChatWebSocketService.setOnDisconnected {}
        ChatWebSocketService.setOnError {}
    }

    private fun setupWebSocketListeners(tvStatus: TextView?) {
        ChatWebSocketService.setOnMessageReceived { payload ->
            if (payload.conversaId == chatId) {
                addMessage(payload.toChatMessage(currentUserId))
            }
        }

        ChatWebSocketService.setOnMessageDelivered { clientId, serverMessageId ->
            pendingLocalIds[clientId]?.let { localMessage ->
                pendingLocalIds.remove(clientId)
                replaceMessage(localMessage.id, localMessage.copy(id = serverMessageId.toString()))
            }
        }

        ChatWebSocketService.setOnConnected {
            tvStatus?.text = "Online"
            tvStatus?.setTextColor(resources.getColor(R.color.green, null))
        }

        ChatWebSocketService.setOnDisconnected {
            tvStatus?.text = "Offline"
            tvStatus?.setTextColor(resources.getColor(R.color.red, null))
        }

        ChatWebSocketService.setOnError {
            tvStatus?.text = "Erro de ligação"
            tvStatus?.setTextColor(resources.getColor(R.color.red, null))
        }
    }

    private fun addMessage(message: ChatMessage) {
        if (message.senderId == currentUserId.toString()) {
            val matching = pendingLocalIds.values.firstOrNull {
                it.message == message.message && it.chatId == message.chatId
            }
            if (matching != null) return
        }
        if (messages.any { it.id == message.id }) return
        messages.add(message)
        adapter.submitList(messages.toList()) {
            view?.findViewById<RecyclerView>(R.id.recyclerViewGroupMessages)
                ?.scrollToPosition(messages.size - 1)
        }
    }

    private fun replaceMessage(oldId: String, newMessage: ChatMessage) {
        val index = messages.indexOfFirst { it.id == oldId }
        if (index >= 0) {
            messages[index] = newMessage
            adapter.submitList(messages.toList())
        }
    }

    private fun loadMessages(chatId: Long, progressBar: ProgressBar?) {
        val token = sessionManager.getToken() ?: return
        progressBar?.visibility = View.VISIBLE

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val response = RetrofitClient.erpApiService.getChatMessages(
                    token = "Bearer $token",
                    conversaId = chatId.toString()
                )
                withContext(Dispatchers.Main) {
                    progressBar?.visibility = View.GONE
                    if (response.isSuccessful) {
                        val list = response.body()?.map { backendMessage ->
                            backendMessage.toChatMessage().copy(chatId = chatId.toString())
                        } ?: emptyList()
                        messages.clear()
                        messages.addAll(list)
                        adapter.submitList(messages.toList()) {
                            if (messages.isNotEmpty()) {
                                view?.findViewById<RecyclerView>(R.id.recyclerViewGroupMessages)
                                    ?.scrollToPosition(messages.size - 1)
                            }
                        }
                    } else {
                        Toast.makeText(context, "Erro ao carregar mensagens", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    progressBar?.visibility = View.GONE
                    Toast.makeText(context, "Falha de rede: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun sendMessage(message: String) {
        if (chatId == 0L || currentUserId == 0L) return

        val clientId = ChatWebSocketService.sendMessage(chatId, message, Constants.CHAT_TYPE_GROUP)
        val optimisticMessage = ChatMessage(
            id = "local_${System.currentTimeMillis()}",
            chatId = chatId.toString(),
            senderId = currentUserId.toString(),
            senderName = sessionManager.getUserName() ?: "Eu",
            message = message,
            timestamp = System.currentTimeMillis().toString(),
            isRead = true
        )
        pendingLocalIds[clientId] = optimisticMessage
        addMessage(optimisticMessage)

        if (!ChatWebSocketService.isConnected) {
            sendMessageViaHttp(chatId, message)
        }
    }

    private fun sendMessageViaHttp(chatId: Long, message: String) {
        val token = sessionManager.getToken() ?: return
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val response = RetrofitClient.erpApiService.sendChatMessage(
                    token = "Bearer $token",
                    conversaId = chatId.toString(),
                    request = ChatMessageRequest(conteudo = message)
                )
                withContext(Dispatchers.Main) {
                    if (!response.isSuccessful) {
                        Toast.makeText(context, "Erro ao enviar mensagem", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(context, "Falha ao enviar: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}
