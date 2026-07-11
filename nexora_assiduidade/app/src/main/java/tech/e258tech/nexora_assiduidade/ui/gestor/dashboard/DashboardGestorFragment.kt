package tech.e258tech.nexora_assiduidade.ui.gestor.dashboard

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Dashboard principal do Gestor
 * Exibe estatísticas da equipa
 */
class DashboardGestorFragment : Fragment() {

    private lateinit var sessionManager: SessionManager
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_dashboard, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        val tvTotal = view.findViewById<TextView>(R.id.tvTotalFuncionarios)
        val tvPresentes = view.findViewById<TextView>(R.id.tvPresentesHoje)
        val btnLogout = view.findViewById<Button>(R.id.btnLogoutGestor)
        
        // TODO: Carregar dados da API
        tvTotal.text = "0"
        tvPresentes.text = "0"

        btnLogout.setOnClickListener {
            sessionManager.clearSession()
            startActivity(Intent(requireContext(), LoginActivity::class.java))
            activity?.finish()
        }
    }
}
