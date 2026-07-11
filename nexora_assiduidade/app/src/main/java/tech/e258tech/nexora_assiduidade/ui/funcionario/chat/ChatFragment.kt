package tech.e258tech.nexora_assiduidade.ui.funcionario.chat

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Chat Geral
 * Lista de conversas de chat
 */
class ChatFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_chat, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewChats)
        recyclerView.layoutManager = LinearLayoutManager(context)
        
        // TODO: Carregar lista de chats da API
    }
}
