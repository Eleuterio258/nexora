package tech.e258tech.nexora_assiduidade.ui.funcionario.agenda

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Detalhe do Item de Agenda
 * Exibe detalhes de um item específico da agenda
 */
class AgendaItemDetailFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_agenda_item_detail, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val tvTitle = view.findViewById<TextView>(R.id.tvItemTitle)
        val tvDescription = view.findViewById<TextView>(R.id.tvItemDescription)
        val tvDuration = view.findViewById<TextView>(R.id.tvItemDuration)
        
        // TODO: Carregar detalhes do item
        tvTitle.text = "Título do Item"
        tvDescription.text = "Descrição do item de agenda"
        tvDuration.text = "Duração: 30 minutos"
    }
}
