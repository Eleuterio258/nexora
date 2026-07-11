package tech.e258tech.nexora_assiduidade.ui.funcionario.agenda

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.floatingactionbutton.FloatingActionButton
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Agenda de Reuniões
 * Exibe lista de reuniões agendadas
 */
class AgendaFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_agenda, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewAgenda)
        val fabNewMeeting = view.findViewById<FloatingActionButton>(R.id.fabNewMeeting)
        
        recyclerView.layoutManager = LinearLayoutManager(context)
        
        fabNewMeeting.setOnClickListener {
            parentFragmentManager.beginTransaction()
                .replace(R.id.fragment_container, CreateMeetingFragment())
                .addToBackStack(null)
                .commit()
        }
        
        // TODO: Carregar reuniões da API
    }
}
