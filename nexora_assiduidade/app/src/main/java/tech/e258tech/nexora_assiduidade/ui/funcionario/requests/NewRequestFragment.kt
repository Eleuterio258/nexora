package tech.e258tech.nexora_assiduidade.ui.funcionario.requests

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
 * Tela de Novo Pedido de Férias
 * Formulário para solicitar férias
 */
class NewRequestFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_new_request, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        val etStartDate = view.findViewById<EditText>(R.id.etStartDate)
        val etEndDate = view.findViewById<EditText>(R.id.etEndDate)
        val etMotivo = view.findViewById<EditText>(R.id.etMotivo)
        val btnSubmit = view.findViewById<Button>(R.id.btnSubmitRequest)
        
        btnSubmit.setOnClickListener {
            val startDate = etStartDate.text.toString()
            val endDate = etEndDate.text.toString()
            val motivo = etMotivo.text.toString()
            
            if (startDate.isEmpty() || endDate.isEmpty() || motivo.isEmpty()) {
                Toast.makeText(context, "Preencha todos os campos", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            
            // TODO: Enviar pedido para API
            Toast.makeText(context, "Pedido enviado com sucesso!", Toast.LENGTH_SHORT).show()
            parentFragmentManager.popBackStack()
        }
    }
}
