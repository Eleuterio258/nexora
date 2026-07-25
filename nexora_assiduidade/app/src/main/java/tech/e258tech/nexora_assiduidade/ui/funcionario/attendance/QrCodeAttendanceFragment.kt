package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.QRValidateDeviceRequest
import tech.e258tech.nexora_assiduidade.data.model.response.QRValidateDeviceResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository
import tech.e258tech.nexora_assiduidade.ui.common.CaptureActivityPortrait
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
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    private lateinit var btnScan: Button
    private lateinit var tvQrInfo: TextView

    private var currentLocation: Location? = null

    private val scanLauncher = registerForActivityResult(ScanContract()) { result ->
        if (result.contents != null) {
            validateQrAndRegister(result.contents)
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

    private val locationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (permissions.entries.any { it.value }) {
            fetchLocation()
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
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(requireContext())

        btnScan = view.findViewById(R.id.btnScan)
        tvQrInfo = view.findViewById(R.id.tvQrInfo)

        requestLocationPermission()

        btnScan.setOnClickListener {
            when {
                ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED -> startScan()
                else -> cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
            }
        }

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }
    }

    private fun requestLocationPermission() {
        val hasFine = ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!hasFine && !hasCoarse) {
            locationPermissionLauncher.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        } else {
            fetchLocation()
        }
    }

    private fun fetchLocation() {
        if (ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        uiScope.launch {
            try {
                currentLocation = withContext(Dispatchers.IO) {
                    fusedLocationClient.lastLocation.await()
                }
            } catch (_: Exception) {
                // Localização é opcional.
            }
        }
    }

    private fun startScan() {
        val options = ScanOptions()
            .setPrompt("Aproxime o QR Code do leitor")
            .setBeepEnabled(true)
            .setOrientationLocked(false)
            .setCaptureActivity(CaptureActivityPortrait::class.java)
        scanLauncher.launch(options)
    }

    private fun validateQrAndRegister(qrCode: String) {
        val userId = sessionManager.getUserId()
        val token = sessionManager.getToken()
        if (userId.isNullOrBlank() || token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        tvQrInfo.text = "A validar QR Code..."

        uiScope.launch {
            val validateResult: Pair<QRValidateDeviceResponse?, String?> = withContext(Dispatchers.IO) {
                try {
                    val response = RetrofitClient.erpApiService.validateQrDevice(
                        BuildConfig.DEVICE_API_KEY,
                        QRValidateDeviceRequest(qr_code = qrCode)
                    )
                    if (response.isSuccessful && response.body() != null) {
                        response.body()!! to null
                    } else {
                        null to ApiUtils.errorMessage(response)
                    }
                } catch (e: Exception) {
                    null to (e.message ?: "Erro na validacao do QR Code")
                }
            }

            val response = validateResult.first
            val message = validateResult.second

            if (response == null || !response.valid) {
                setLoading(false)
                tvQrInfo.text = "QR Code invalido."
                Toast.makeText(context, message ?: "QR Code invalido.", Toast.LENGTH_LONG).show()
                return@launch
            }

            val request = ClockRegisterRequest(
                idempotency_key = UUID.randomUUID().toString(),
                user_id = userId,
                device_id = sessionManager.getOrCreateDeviceId(),
                event_type = Constants.EVENT_AUTO,
                recorded_at = DateTimeUtils.nowForApi(),
                source = Constants.SOURCE_QR_CODE,
                geo_lat = currentLocation?.latitude,
                geo_lng = currentLocation?.longitude,
                qr_token_id = response.token_id,
                localidade_id = response.location_id?.toLongOrNull()
            )

            val registerResult = withContext(Dispatchers.IO) {
                attendanceRepository.registerClock(request)
            }

            setLoading(false)

            when (registerResult) {
                is AttendanceRepository.RegisterResult.Success -> {
                    tvQrInfo.text = "Registo de presença realizado com sucesso."
                    Toast.makeText(context, "Registo de presença realizado com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                }
                is AttendanceRepository.RegisterResult.SavedOffline -> {
                    tvQrInfo.text = "Sem internet. Registo guardado."
                    Toast.makeText(context, "Sem internet. Registo guardado e sera sincronizado automaticamente.", Toast.LENGTH_LONG).show()
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
