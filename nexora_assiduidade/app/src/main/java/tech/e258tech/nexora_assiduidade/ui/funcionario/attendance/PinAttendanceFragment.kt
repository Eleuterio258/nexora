package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.RadioGroup
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
import tech.e258tech.nexora_assiduidade.data.model.PinValidateRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.RoleUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por PIN.
 *
 * O utilizador seleciona Entrada/Saida, digita o PIN e o codigo e validado
 * directamente no Nexora ERP via POST /api/authcode/pin/validate (deixou de
 * passar pelo proxy do FaceClock em 2026-07-12) — devolve um login completo
 * (tokens+utilizador), tal como /api/auth/login, por isso a sessao e
 * actualizada com o resultado antes de registar o ponto.
 */
class PinAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
    private lateinit var attendanceRepository: AttendanceRepository

    private lateinit var radioGroupType: RadioGroup
    private lateinit var etPin: EditText
    private lateinit var btnValidatePin: Button

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_pin_attendance, container, false)
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
        etPin = view.findViewById(R.id.etPin)
        btnValidatePin = view.findViewById(R.id.btnValidatePin)

        btnValidatePin.setOnClickListener {
            val selectedId = radioGroupType.checkedRadioButtonId
            if (selectedId == -1) {
                Toast.makeText(context, "Selecione Entrada ou Saida", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val pin = etPin.text.toString().trim()
            if (pin.length < 4) {
                Toast.makeText(context, "PIN deve ter pelo menos 4 digitos", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val eventType = if (selectedId == R.id.radioEntrada) {
                Constants.EVENT_ENTRY
            } else {
                Constants.EVENT_EXIT
            }

            validatePinAndRegister(pin, eventType)
        }
    }

    private fun validatePinAndRegister(pin: String, eventType: String) {
        val email = sessionManager.getUserEmail()
        if (email.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        btnValidatePin.isEnabled = false

        uiScope.launch {
            val validateResult: Pair<Boolean, String?> = withContext(Dispatchers.IO) {
                try {
                    val response = RetrofitClient.erpApiService.validatePin(
                        PinValidateRequest(email = email, pin = pin)
                    )
                    if (response.isSuccessful && response.body() != null) {
                        val payload = response.body()!!
                        val role = RoleUtils.fromErpLogin(payload.tipo, payload.modulos)
                        sessionManager.saveSession(
                            token = payload.access_token,
                            refreshToken = payload.refresh_token,
                            userId = payload.user.id.toString(),
                            userName = payload.user.nome,
                            userEmail = payload.user.email,
                            userRole = role,
                            employeeCode = payload.user.email
                        )
                        true to null
                    } else {
                        false to ApiUtils.errorMessage(response)
                    }
                } catch (e: Exception) {
                    false to (e.message ?: "Erro na validacao do PIN")
                }
            }

            val valid = validateResult.first
            val message = validateResult.second

            if (!valid) {
                btnValidatePin.isEnabled = true
                Toast.makeText(context, message ?: "PIN invalido.", Toast.LENGTH_LONG).show()
                return@launch
            }

            val userId = sessionManager.getUserId() ?: run {
                btnValidatePin.isEnabled = true
                Toast.makeText(context, "Sessao invalida apos validacao do PIN.", Toast.LENGTH_LONG).show()
                return@launch
            }

            val request = ClockRegisterRequest(
                idempotency_key = UUID.randomUUID().toString(),
                user_id = userId,
                device_id = sessionManager.getOrCreateDeviceId(),
                event_type = eventType,
                recorded_at = DateTimeUtils.nowForApi(),
                source = Constants.SOURCE_PIN
            )

            val registerResult = withContext(Dispatchers.IO) {
                attendanceRepository.registerClock(request)
            }

            btnValidatePin.isEnabled = true
            val action = if (eventType == Constants.EVENT_ENTRY) "entrada" else "saida"

            when (registerResult) {
                is AttendanceRepository.RegisterResult.Success -> {
                    Toast.makeText(context, "Registo de $action realizado com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    Toast.makeText(context, "Sem internet. Registo de $action guardado e sera sincronizado automaticamente.", Toast.LENGTH_LONG).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.Error -> {
                    Toast.makeText(context, registerResult.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }
}
