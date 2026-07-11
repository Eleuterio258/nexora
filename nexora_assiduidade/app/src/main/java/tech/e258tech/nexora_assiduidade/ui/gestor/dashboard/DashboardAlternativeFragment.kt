package tech.e258tech.nexora_assiduidade.ui.gestor.dashboard

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R

/**
 * Dashboard alternativo do Gestor (versão anterior)
 */
class DashboardAlternativeFragment : Fragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_dashboard_alternative, container, false)
    }
}
