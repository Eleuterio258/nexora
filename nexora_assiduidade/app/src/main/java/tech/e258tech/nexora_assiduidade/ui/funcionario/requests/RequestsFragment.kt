package tech.e258tech.nexora_assiduidade.ui.funcionario.requests

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Pedidos de Férias
 * Exibe lista de pedidos de férias/ausência
 */
class RequestsFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_requests, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewRequests)
        val btnNewRequest = view.findViewById<Button>(R.id.btnNewRequest)
        
        recyclerView.layoutManager = LinearLayoutManager(context)
        
        btnNewRequest.setOnClickListener {
            parentFragmentManager.beginTransaction()
                .replace(R.id.fragment_container, NewRequestFragment())
                .addToBackStack(null)
                .commit()
        }
        
        // TODO: Carregar pedidos da API
    }
}
