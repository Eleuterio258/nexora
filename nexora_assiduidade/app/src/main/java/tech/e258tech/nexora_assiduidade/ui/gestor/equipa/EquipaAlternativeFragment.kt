package tech.e258tech.nexora_assiduidade.ui.gestor.equipa

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Equipa alternativa (versão anterior)
 */
class EquipaAlternativeFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_equipa_alternative, container, false)
    }
}
