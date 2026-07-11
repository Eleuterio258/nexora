package tech.e258tech.nexora_assiduidade.ui.funcionario.home

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.local.AppDatabase
import tech.e258tech.nexora_assiduidade.data.local.PendingEventEntity
import tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.FacialAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.FingerprintAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.ManualAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.NfcAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.PinAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.QrCodeAttendanceFragment
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.SelfieGpsAttendanceFragment
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela Home do Funcionário
 * Exibe as 7 opções de registro de presença e o indicador de eventos pendentes.
 */
class HomeFuncionarioFragment : Fragment() {

    private lateinit var sessionManager: SessionManager
    private lateinit var tvPendingSync: TextView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_home, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        tvPendingSync = view.findViewById(R.id.tvPendingSync)

        view.findViewById<Button>(R.id.btnLogoutHome).setOnClickListener {
            sessionManager.clearSession()
            startActivity(Intent(requireContext(), LoginActivity::class.java))
            activity?.finish()
        }

        // Saudação
        view.findViewById<TextView>(R.id.tvGreeting).text =
            "Olá, ${sessionManager.getUserName() ?: "Funcionário"}!"

        // Configurar cliques nos cards de método
        view.findViewById<CardView>(R.id.cardManual).setOnClickListener {
            openFragment(ManualAttendanceFragment())
        }

        view.findViewById<CardView>(R.id.cardQrCode).setOnClickListener {
            openFragment(QrCodeAttendanceFragment())
        }

        view.findViewById<CardView>(R.id.cardFacial).setOnClickListener {
            openFragment(FacialAttendanceFragment())
        }

        view.findViewById<CardView>(R.id.cardSelfieGps).setOnClickListener {
            openFragment(SelfieGpsAttendanceFragment())
        }

        view.findViewById<CardView>(R.id.cardPin).setOnClickListener {
            openFragment(PinAttendanceFragment())
        }

        view.findViewById<CardView>(R.id.cardNfc).setOnClickListener {
            openFragment(NfcAttendanceFragment())
        }

        view.findViewById<CardView>(R.id.cardFingerprint).setOnClickListener {
            openFragment(FingerprintAttendanceFragment())
        }

        loadPendingEventsCount()
    }

    override fun onResume() {
        super.onResume()
        loadPendingEventsCount()
    }

    private fun openFragment(fragment: Fragment) {
        parentFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .addToBackStack(null)
            .commit()
    }

    /**
     * Carrega a quantidade de eventos pendentes de sincronizacao e atualiza o indicador.
     */
    private fun loadPendingEventsCount() {
        lifecycleScope.launch {
            val count = withContext(Dispatchers.IO) {
                AppDatabase.getInstance(requireContext())
                    .pendingEventDao()
                    .countByStatus(PendingEventEntity.SyncStatus.PENDING)
            }

            if (count > 0) {
                tvPendingSync.visibility = View.VISIBLE
                tvPendingSync.text = if (count == 1) {
                    "1 registo pendente de sincronizacao"
                } else {
                    "$count registos pendentes de sincronizacao"
                }
            } else {
                tvPendingSync.visibility = View.GONE
            }
        }
    }
}
