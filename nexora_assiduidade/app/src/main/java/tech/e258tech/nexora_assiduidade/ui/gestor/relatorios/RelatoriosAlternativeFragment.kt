package tech.e258tech.nexora_assiduidade.ui.gestor.relatorios

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Relatórios alternativos (versão anterior)
 */
class RelatoriosAlternativeFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_relatorios_alternative, container, false)
    }
}
