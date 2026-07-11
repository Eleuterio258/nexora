package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R
import java.text.SimpleDateFormat
import java.util.*

/**
 * Tela de Confirmação de Sucesso
 * Exibe confirmação após registro de presença
 */
class SuccessAttendanceFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_success_attendance, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val tvMessage = view.findViewById<TextView>(R.id.tvSuccessMessage)
        val tvDateTime = view.findViewById<TextView>(R.id.tvDateTime)
        val btnDone = view.findViewById<Button>(R.id.btnDone)
        
        val now = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault()).format(Date())
        tvDateTime.text = "Registrado em: $now"
        tvMessage.text = "Presença registrada com sucesso!"
        
        btnDone.setOnClickListener {
            parentFragmentManager.popBackStack()
        }
    }
}
