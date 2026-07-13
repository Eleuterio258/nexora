package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.QRValidateDeviceRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por leitura de QR Code.
 *
 * Usa a biblioteca ZXing (journeyapps) para ler um QR Code e valida-o
 * directamente no Nexora ERP (`POST /api/hardware/assiduidade/qr/validar`,
 * API Key de device) desde 2026-07-13 — deixou de passar pelo proxy do
 * FaceClock. Se valido, regista o ponto.
 */
class QrCodeAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
    private lateinit var attendanceRepository: AttendanceRepository

    private lateinit var radioGroupType: RadioGroup
    private lateinit var btnScan: Button
    private lateinit var tvQrInfo: TextView

    private val scanLauncher = registerForActivityResult(ScanContract()) { result ->
        if (result.contents != null) {
            val selectedId = radioGroupType.checkedRadioButtonId
            if (selectedId == -1) {
                Toast.makeText(context, "Selecione Entrada ou Saida", Toast.LENGTH_SHORT).show()
                return@registerForActivityResult
            }
            val eventType = if (selectedId == R.id.radioEntrada) {
                Constants.EVENT_ENTRY
            } else {
                Constants.EVENT_EXIT
            }
            validateQrAndRegister(result.contents, eventType)
        }
    }

    private val cameraPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            startScan()
        } else {
            Toast.makeText(context, "Permissao da camara necessaria para ler QR Code.", Toast.LENGTH_LONG).show()
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_qr_code_attendance, container, false)
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
        btnScan = view.findViewById(R.id.btnScan)
        tvQrInfo = view.findViewById(R.id.tvQrInfo)

        btnScan.setOnClickListener {
            when (PackageManager.PERMISSION_GRANTED) {
                ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.CAMERA) -> startScan()
                else -> cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
            }
        }
    }

    private fun startScan() {
        val options = ScanOptions()
            .setPrompt("Aproxime o QR Code do leitor")
            .setBeepEnabled(true)
            .setOrientationLocked(false)
            .setCaptureActivity(tech.e258tech.nexora_assiduidade.ui.common.CaptureActivityPortrait::class.java)
        scanLauncher.launch(options)
    }

    private fun validateQrAndRegister(qrCode: String, eventType: String) {
        val userId = sessionManager.getUserId()
        val token = sessionManager.getToken()
        if (userId.isNullOrBlank() || token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        tvQrInfo.text = "A validar QR Code..."

        uiScope.launch {
            val validateResult: Pair<Boolean, String?> = withContext(Dispatchers.IO) {
                try {
                    val response = RetrofitClient.erpApiService.validateQrDevice(
                        BuildConfig.DEVICE_API_KEY,
                        QRValidateDeviceRequest(qr_code = qrCode)
                    )
                    if (response.isSuccessful && response.body() != null) {
                        val body = response.body()!!
                        body.valid to null
                    } else {
                        false to ApiUtils.errorMessage(response)
                    }
                } catch (e: Exception) {
                    false to (e.message ?: "Erro na validacao do QR Code")
                }
            }

            val valid = validateResult.first
            val message = validateResult.second

            if (!valid) {
                setLoading(false)
                tvQrInfo.text = "QR Code invalido."
                Toast.makeText(context, message ?: "QR Code invalido.", Toast.LENGTH_LONG).show()
                return@launch
            }

            val request = ClockRegisterRequest(
                idempotency_key = UUID.randomUUID().toString(),
                user_id = userId,
                device_id = sessionManager.getOrCreateDeviceId(),
                event_type = eventType,
                recorded_at = DateTimeUtils.nowForApi(),
                source = Constants.SOURCE_QR_CODE
            )

            val registerResult = withContext(Dispatchers.IO) {
                attendanceRepository.registerClock(request)
            }

            setLoading(false)
            val action = if (eventType == Constants.EVENT_ENTRY) "entrada" else "saida"

            when (registerResult) {
                is AttendanceRepository.RegisterResult.Success -> {
                    tvQrInfo.text = "Registo de $action realizado com sucesso."
                    Toast.makeText(context, "Registo de $action realizado com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    tvQrInfo.text = "Sem internet. Registo guardado."
                    Toast.makeText(context, "Sem internet. Registo de $action guardado e sera sincronizado automaticamente.", Toast.LENGTH_LONG).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.Error -> {
                    tvQrInfo.text = registerResult.message
                    Toast.makeText(context, registerResult.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        btnScan.isEnabled = !isLoading
    }
}
