package tech.e258tech.nexora_assiduidade.ui.funcionario.agenda

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Tela de Criação de Reunião
 * Formulário para criar nova reunião
 */
class CreateMeetingFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_create_meeting, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val etTitle = view.findViewById<EditText>(R.id.etMeetingTitle)
        val etDate = view.findViewById<EditText>(R.id.etMeetingDate)
        val etTime = view.findViewById<EditText>(R.id.etMeetingTime)
        val btnCreate = view.findViewById<Button>(R.id.btnCreateMeeting)
        
        btnCreate.setOnClickListener {
            val title = etTitle.text.toString()
            val date = etDate.text.toString()
            val time = etTime.text.toString()
            
            if (title.isEmpty() || date.isEmpty()) {
                Toast.makeText(context, "Preencha os campos obrigatórios", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            
            // TODO: Criar reunião via API
            Toast.makeText(context, "Reunião criada com sucesso!", Toast.LENGTH_SHORT).show()
            parentFragmentManager.popBackStack()
        }
    }
}
