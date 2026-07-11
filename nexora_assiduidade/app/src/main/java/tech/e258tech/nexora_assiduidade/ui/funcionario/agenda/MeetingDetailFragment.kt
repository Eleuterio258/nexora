package tech.e258tech.nexora_assiduidade.ui.funcionario.agenda

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Detalhe da Reunião
 * Exibe detalhes de uma reunião específica
 */
class MeetingDetailFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_meeting_detail, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val tvTitle = view.findViewById<TextView>(R.id.tvMeetingTitle)
        val tvDateTime = view.findViewById<TextView>(R.id.tvMeetingDateTime)
        val tvLocation = view.findViewById<TextView>(R.id.tvMeetingLocation)
        val tvDescription = view.findViewById<TextView>(R.id.tvMeetingDescription)
        
        // TODO: Carregar detalhes da API
        tvTitle.text = "Título da Reunião"
        tvDateTime.text = "Data e Hora"
        tvLocation.text = "Local"
        tvDescription.text = "Descrição da reunião..."
    }
}
