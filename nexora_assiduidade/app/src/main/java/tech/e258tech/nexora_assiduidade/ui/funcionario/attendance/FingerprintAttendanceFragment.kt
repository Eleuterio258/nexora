package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ProgressBar
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository
import tech.e258tech.nexora_assiduidade.utils.BiometricHelper
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por impressao digital.
 *
 * NOTA DE SEGURANCA/PRIVACIDADE:
 * A API BiometricPrompt do Android NAO expoe a imagem da impressao digital, o template
 * nem identifica qual dedo ou pessoa foi reconhecida. O utilizador deve estar previamente
 * autenticado (login no ERP); a biometria funciona apenas como prova de presenca humana
 * vinculada a essa sessao.
 */
class FingerprintAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
    private lateinit var attendanceRepository: AttendanceRepository

    private lateinit var radioGroupType: RadioGroup
    private lateinit var btnAuthenticate: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var tvStatus: TextView

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_fingerprint_attendance, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        attendanceRepository = AttendanceRepository(requireContext())

        radioGroupType = view.findViewById(R.id.radioGroupType)
        btnAuthenticate = view.findViewById(R.id.btnAuthenticate)
        progressBar = view.findViewById(R.id.progressBar)
        tvStatus = view.findViewById(R.id.tvStatus)

        btnAuthenticate.setOnClickListener {
            val selectedId = radioGroupType.checkedRadioButtonId
            if (selectedId == -1) {
                Toast.makeText(context, "Selecione Entrada ou Saida", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val eventType = if (selectedId == R.id.radioEntrada) {
                Constants.EVENT_ENTRY
            } else {
                Constants.EVENT_EXIT
            }

            startBiometricAuthentication(eventType)
        }
    }

    private fun startBiometricAuthentication(eventType: String) {
        val activity = requireActivity()

        when (val status = BiometricHelper.checkStatus(activity)) {
            is BiometricHelper.BiometricStatus.Available -> {
                setLoading(true, "Toque no sensor biometrico...")
                BiometricHelper.authenticate(
                    activity = activity,
                    title = "Registar ${if (eventType == Constants.EVENT_ENTRY) "entrada" else "saida"}",
                    subtitle = "Confirme a sua identidade",
                    description = "Utilize a impressao digital registada no dispositivo.",
                    callback = object : BiometricHelper.AuthenticationCallback {
                        override fun onSuccess() {
                            registerClock(eventType)
                        }

                        override fun onError(errorCode: Int, errorMessage: String) {
                            setLoading(false)
                            tvStatus.text = errorMessage
                            Toast.makeText(context, errorMessage, Toast.LENGTH_LONG).show()
                        }

                        override fun onFailed() {
                            setLoading(false)
                            tvStatus.text = "Impressao digital nao reconhecida. Tente novamente."
                        }

                        override fun onCancelled() {
                            setLoading(false)
                            tvStatus.text = "Autenticacao cancelada."
                        }
                    }
                )
            }
            is BiometricHelper.BiometricStatus.Unavailable -> {
                Toast.makeText(context, status.reason, Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun registerClock(eventType: String) {
        val userId = sessionManager.getUserId()

        if (userId.isNullOrBlank()) {
            setLoading(false)
            Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG)
                .show()
            return
        }

        setLoading(true, "A registar o ponto...")

        val request = ClockRegisterRequest(
            idempotency_key = UUID.randomUUID().toString(),
            user_id = userId,
            device_id = sessionManager.getOrCreateDeviceId(),
            event_type = eventType,
            recorded_at = DateTimeUtils.nowForApi(),
            source = Constants.SOURCE_FINGERPRINT,
            confidence_score = 1.0
        )

        uiScope.launch {
            val result = withContext(Dispatchers.IO) {
                attendanceRepository.registerClock(request)
            }

            setLoading(false)

            val action = if (eventType == Constants.EVENT_ENTRY) "entrada" else "saida"
            when (result) {
                is AttendanceRepository.RegisterResult.Success -> {
                    tvStatus.text = "Registo de $action realizado com sucesso."
                    Toast.makeText(
                        context,
                        "Registo de $action realizado com sucesso.",
                        Toast.LENGTH_SHORT
                    ).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    tvStatus.text = "Sem internet. Registo de $action guardado localmente."
                    Toast.makeText(
                        context,
                        "Sem internet. Registo de $action guardado e sera sincronizado automaticamente.",
                        Toast.LENGTH_LONG
                    ).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.Error -> {
                    tvStatus.text = result.message
                    Toast.makeText(context, result.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun setLoading(isLoading: Boolean, statusText: String = "") {
        btnAuthenticate.isEnabled = !isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        if (statusText.isNotBlank()) {
            tvStatus.text = statusText
        }
    }
}
