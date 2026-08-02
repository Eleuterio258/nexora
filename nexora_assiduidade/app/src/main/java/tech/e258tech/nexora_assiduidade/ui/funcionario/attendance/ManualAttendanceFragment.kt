package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.android.material.button.MaterialButtonToggleGroup
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
import tech.e258tech.nexora_assiduidade.utils.PermissionUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Registo manual do próprio ponto. A partir de agora este método é reservado a
 * gestores com permissão `recursos-humanos:gerir_funcionarios` — a app já
 * esconde o card na Home, e a verificação defensiva aqui impede abertura
 * directa ou chamadas via deep-link.
 */
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

        val btnRegister = view.findViewById<Button>(R.id.btnRegister)
        val rgEventType = view.findViewById<MaterialButtonToggleGroup>(R.id.rgEventType)
        val tvStatus = view.findViewById<TextView>(R.id.tvManualStatus)
        val sessionManager = SessionManager(requireContext())
        attendanceRepository = AttendanceRepository(requireContext())

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        if (!PermissionUtils.has(sessionManager, "recursos-humanos", "gerir_funcionarios")) {
            tvStatus.text = getString(R.string.manual_attendance_no_permission)
            rgEventType.isEnabled = false
            view.findViewById<View>(R.id.rbEntry).isEnabled = false
            view.findViewById<View>(R.id.rbExit).isEnabled = false
            btnRegister.isEnabled = false
            return
        }

        btnRegister.setOnClickListener {
            val eventType = when (rgEventType.checkedButtonId) {
                R.id.rbEntry -> Constants.EVENT_ENTRY
                R.id.rbExit -> Constants.EVENT_EXIT
                else -> {
                    tvStatus.text = getString(R.string.manual_attendance_select_type_error)
                    return@setOnClickListener
                }
            }

            val userId = sessionManager.getUserId()
            if (userId.isNullOrBlank()) {
                Toast.makeText(context, R.string.manual_attendance_invalid_session, Toast.LENGTH_LONG)
                    .show()
                return@setOnClickListener
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

            when (result) {
                is AttendanceRepository.RegisterResult.Success -> {
                    Toast.makeText(
                        context,
                        R.string.manual_attendance_success,
                        Toast.LENGTH_SHORT
                    ).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    Toast.makeText(
                        context,
                        R.string.manual_attendance_saved_offline,
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
