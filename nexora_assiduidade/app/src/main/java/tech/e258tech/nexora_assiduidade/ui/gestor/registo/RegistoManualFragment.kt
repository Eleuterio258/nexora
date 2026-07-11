package tech.e258tech.nexora_assiduidade.ui.gestor.registo

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
 * Registro Manual de Funcionário
 */
class RegistoManualFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_registo_manual, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val etEmployeeId = view.findViewById<EditText>(R.id.etEmployeeId)
        val btnRegister = view.findViewById<Button>(R.id.btnRegister)
        
        btnRegister.setOnClickListener {
            // TODO: Implementar registro
            Toast.makeText(context, "Registro realizado", Toast.LENGTH_SHORT).show()
        }
    }
}
