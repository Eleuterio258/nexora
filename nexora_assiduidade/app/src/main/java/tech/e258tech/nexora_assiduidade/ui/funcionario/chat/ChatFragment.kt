package tech.e258tech.nexora_assiduidade.ui.funcionario.chat

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ProgressBar
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.chat.Conversation
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.funcionario.chat.adapter.ConversationAdapter
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de Chat Geral
 * Lista de conversas do utilizador autenticado.
 */
class ChatFragment : Fragment() {

    private lateinit var sessionManager: SessionManager
    private lateinit var adapter: ConversationAdapter
    private val conversations = mutableListOf<Conversation>()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_chat, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewChats)
        val progressBar = view.findViewById<ProgressBar?>(R.id.progressBarChats)

        adapter = ConversationAdapter { conversation ->
            openConversation(conversation)
        }
        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.adapter = adapter

        loadConversas(progressBar)
    }

    private fun loadConversas(progressBar: ProgressBar?) {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessão inválida", Toast.LENGTH_SHORT).show()
            return
        }

        progressBar?.visibility = View.VISIBLE
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val response = RetrofitClient.erpApiService.getConversas("Bearer $token")
                withContext(Dispatchers.Main) {
                    progressBar?.visibility = View.GONE
                    if (response.isSuccessful) {
                        conversations.clear()
                        conversations.addAll(response.body() ?: emptyList())
                        adapter.submitList(conversations.toList())
                    } else {
                        Toast.makeText(context, "Erro ao carregar conversas", Toast.LENGTH_SHORT).show()
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

    private fun openConversation(conversation: Conversation) {
        val fragment = when (conversation.tipo) {
            "grupo" -> GroupChatFragment.newInstance(conversation.id, conversation.displayName())
            else -> PrivateChatFragment.newInstance(conversation.id, conversation.displayName())
        }

        parentFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .addToBackStack(null)
            .commit()
    }
}
