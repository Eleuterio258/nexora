package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
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
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

class ManualAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var attendanceRepository: AttendanceRepository

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_manual_attendance, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val radioGroup = view.findViewById<RadioGroup>(R.id.radioGroupType)
        val btnRegister = view.findViewById<Button>(R.id.btnRegister)
        val sessionManager = SessionManager(requireContext())
        attendanceRepository = AttendanceRepository(requireContext())

        btnRegister.setOnClickListener {
            val selectedId = radioGroup.checkedRadioButtonId
            if (selectedId == -1) {
                Toast.makeText(context, "Selecione Entrada ou Saida", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val userId = sessionManager.getUserId()
            if (userId.isNullOrBlank()) {
                Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG)
                    .show()
                return@setOnClickListener
            }

            val eventType = if (selectedId == R.id.radioEntrada) {
                Constants.EVENT_ENTRY
            } else {
                Constants.EVENT_EXIT
            }

            btnRegister.isEnabled = false
            registerClock(sessionManager, userId, eventType, btnRegister)
        }
    }

    private fun registerClock(
        sessionManager: SessionManager,
        userId: String,
        eventType: String,
        button: Button
    ) {
        val request = ClockRegisterRequest(
            idempotency_key = UUID.randomUUID().toString(),
            user_id = userId,
            device_id = sessionManager.getOrCreateDeviceId(),
            event_type = eventType,
            recorded_at = DateTimeUtils.nowForApi(),
            source = Constants.SOURCE_MANUAL
        )

        uiScope.launch {
            val result = withContext(Dispatchers.IO) {
                attendanceRepository.registerClock(request)
            }

            button.isEnabled = true
            val action = if (eventType == Constants.EVENT_ENTRY) "entrada" else "saida"

            when (result) {
                is AttendanceRepository.RegisterResult.Success -> {
                    Toast.makeText(
                        context,
                        "Registo de $action realizado com sucesso.",
                        Toast.LENGTH_SHORT
                    ).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    Toast.makeText(
                        context,
                        "Sem internet. Registo de $action guardado e sera sincronizado automaticamente.",
                        Toast.LENGTH_LONG
                    ).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.Error -> {
                    Toast.makeText(context, result.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }
}
