package tech.e258tech.nexora_assiduidade.ui.funcionario.chat

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Chat em Grupo
 * Conversa em grupo com múltiplos participantes
 */
class GroupChatFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_group_chat, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewGroupMessages)
        val etMessage = view.findViewById<EditText>(R.id.etGroupMessage)
        val btnSend = view.findViewById<Button>(R.id.btnSendGroup)
        
        recyclerView.layoutManager = LinearLayoutManager(context)
        
        btnSend.setOnClickListener {
            val message = etMessage.text.toString()
            if (message.isNotEmpty()) {
                // TODO: Enviar mensagem para grupo
                etMessage.text?.clear()
            }
        }
    }
}
