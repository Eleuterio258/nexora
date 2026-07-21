package tech.e258tech.nexora_assiduidade.ui.gestor.mais

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.cardview.widget.CardView
import androidx.fragment.app.Fragment
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.gestor.dispositivos.DispositivosFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.ocorrencias.AlertasFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.ocorrencias.OcorrenciasFragment
import tech.e258tech.nexora_assiduidade.ui.gestor.registo.RegistoManualFragment
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Mais Opções / Configurações — também o ponto de entrada para os ecrãs que
 * não são tabs próprias (Dispositivos, Ocorrências, Alertas, Registo Manual).
 */
class MaisFragment : Fragment() {

    private lateinit var sessionManager: SessionManager

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_mais, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        // Dispositivos exige hardware.ver_dispositivos (router.go:2500);
        // Ocorrências/Alertas exigem recursos-humanos.ver_funcionarios
        // (router.go:1675) — escondidos quando o cargo não tem a acção,
        // em vez de deixar aparecer 403 ao abrir o ecrã.
        val temVerDispositivos = PermissionUtils.has(sessionManager, "hardware", "ver_dispositivos")
        val temVerFuncionarios = PermissionUtils.has(sessionManager, "recursos-humanos", "ver_funcionarios")

        val cardDispositivos = view.findViewById<CardView>(R.id.cardDispositivos)
        val cardOcorrencias = view.findViewById<CardView>(R.id.cardOcorrencias)
        val cardAlertas = view.findViewById<CardView>(R.id.cardAlertas)

        cardDispositivos.visibility = if (temVerDispositivos) View.VISIBLE else View.GONE
        cardOcorrencias.visibility = if (temVerFuncionarios) View.VISIBLE else View.GONE
        cardAlertas.visibility = if (temVerFuncionarios) View.VISIBLE else View.GONE

        cardDispositivos.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(DispositivosFragment())
        }
        cardOcorrencias.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(OcorrenciasFragment())
        }
        cardAlertas.setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(AlertasFragment())
        }
        view.findViewById<CardView>(R.id.cardRegistoManual).setOnClickListener {
            (activity as? LoginActivity)?.pushFragment(RegistoManualFragment())
        }
        view.findViewById<CardView>(R.id.cardConfig).setOnClickListener {
            Toast.makeText(context, "Configurações em breve.", Toast.LENGTH_SHORT).show()
        }
        view.findViewById<CardView>(R.id.cardAjuda).setOnClickListener {
            Toast.makeText(context, "Ajuda em breve.", Toast.LENGTH_SHORT).show()
        }

        val cardLogout = view.findViewById<CardView>(R.id.cardLogout)
        cardLogout.setOnClickListener {
            sessionManager.clearSession()
            startActivity(Intent(requireContext(), LoginActivity::class.java))
            activity?.finish()
        }
    }
}
