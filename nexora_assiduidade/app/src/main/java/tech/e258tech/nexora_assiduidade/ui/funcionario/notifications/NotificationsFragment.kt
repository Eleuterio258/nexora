package tech.e258tech.nexora_assiduidade.ui.funcionario.notifications

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Notificações
 * Centro de notificações do funcionário
 */
class NotificationsFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_notifications, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewNotifications)
        val tvEmpty = view.findViewById<TextView>(R.id.tvEmptyNotifications)
        
        recyclerView.layoutManager = LinearLayoutManager(context)
        
        // TODO: Carregar notificações da API
        tvEmpty.visibility = View.GONE
    }
}
