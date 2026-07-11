package tech.e258tech.nexora_assiduidade.ui.gestor.equipa

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Detalhe do Funcionário
 */
class DetalheFuncionarioFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_detalhe_funcionario, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val tvName = view.findViewById<TextView>(R.id.tvEmployeeName)
        val tvEmail = view.findViewById<TextView>(R.id.tvEmployeeEmail)
        // TODO: Carregar dados
    }
}
