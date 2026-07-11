package tech.e258tech.nexora_assiduidade.ui.funcionario.profile

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
import tech.e258tech.nexora_assiduidade.utils.RoleUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

class ProfileFragment : Fragment() {

    private lateinit var sessionManager: SessionManager

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_profile, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        val tvName = view.findViewById<TextView>(R.id.tvProfileName)
        val tvEmail = view.findViewById<TextView>(R.id.tvProfileEmail)
        val tvRole = view.findViewById<TextView>(R.id.tvProfileRole)
        val btnLogout = view.findViewById<Button>(R.id.btnLogout)

        tvName.text = sessionManager.getUserName() ?: "Utilizador"
        tvEmail.text = sessionManager.getEmployeeCode() ?: sessionManager.getUserEmail() ?: "-"
        tvRole.text = RoleUtils.displayName(sessionManager.getUserRole())

        btnLogout.setOnClickListener {
            sessionManager.clearSession()
            activity?.finish()
            startActivity(Intent(context, LoginActivity::class.java))
        }
    }
}
