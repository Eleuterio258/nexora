package tech.e258tech.nexora_assiduidade.ui.funcionario.requests

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Detalhe do Pedido
 * Exibe detalhes de um pedido de férias
 */
class RequestDetailFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_request_detail, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val tvTitle = view.findViewById<TextView>(R.id.tvRequestTitle)
        val tvStatus = view.findViewById<TextView>(R.id.tvRequestStatus)
        val tvDetails = view.findViewById<TextView>(R.id.tvRequestDetails)
        
        // TODO: Carregar detalhes da API
        tvTitle.text = "Pedido de Férias"
        tvStatus.text = "Status: Pendente"
        tvDetails.text = "Detalhes do pedido..."
    }
}
