package tech.e258tech.nexora_assiduidade.ui.gestor.qrcode

import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ProgressBar
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
import kotlinx.coroutines.CancellationException
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
import tech.e258tech.nexora_assiduidade.utils.HardwareEventMapper
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Gestor lê o QR Code pessoal do funcionário e regista a presença em nome dele.
 */
class GestorLerQrFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
    private lateinit var attendanceRepository: AttendanceRepository
    private lateinit var fusedLocationClient: FusedLocationProviderClient

    private lateinit var btnScan: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var tvInfo: TextView

    private var currentLocation: Location? = null

    private val scanLauncher = registerForActivityResult(ScanContract()) { result ->
        if (result.contents != null) {
            validarERegistar(result.contents)
        }
    }

    private val cameraPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            startScan()
        } else {
            Toast.makeText(context, "Permissão da câmara necessária para ler QR Code.", Toast.LENGTH_LONG).show()
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
        return inflater.inflate(R.layout.gestor_ler_qr, container, false)
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
        progressBar = view.findViewById(R.id.progressBar)
        tvInfo = view.findViewById(R.id.tvInfo)

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        btnScan.setOnClickListener {
            when {
                ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED -> startScan()
                else -> cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
            }
        }

        requestLocationPermission()
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
                // Localização é opcional para este modo.
            }
        }
    }

    private fun startScan() {
        val options = ScanOptions()
            .setPrompt("Aproxime o QR Code pessoal do funcionário")
            .setBeepEnabled(true)
            .setOrientationLocked(false)
            .setCaptureActivity(CaptureActivityPortrait::class.java)
        scanLauncher.launch(options)
    }

    private fun validarERegistar(qrCode: String) {
        val gestorUserId = sessionManager.getUserId()
        if (gestorUserId.isNullOrBlank()) {
            Toast.makeText(context, "Sessão inválida. Faça login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        tvInfo.text = "A validar QR Code..."

        uiScope.launch {
            try {
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
                        null to (e.message ?: "Erro na validação do QR Code")
                    }
                }

                val response = validateResult.first
                val error = validateResult.second

                if (response == null || !response.valid || response.employee_no.isNullOrBlank() || response.funcionario_id == null) {
                    setLoading(false)
                    tvInfo.text = error ?: "QR Code inválido ou não vinculado a funcionário."
                    Toast.makeText(context, error ?: "QR Code inválido ou não vinculado a funcionário.", Toast.LENGTH_LONG).show()
                    return@launch
                }

                tvInfo.text = "A identificar funcionário..."

                // Resolve o employee_code pelo funcionario_id devolvido na validação
                // do QR — não pela sessão actual, que é a do gestor, não a do
                // funcionário cuja presença está a ser registada.
                val employeeCode = withContext(Dispatchers.IO) {
                    HardwareEventMapper.resolveEmployeeCodeById(response.funcionario_id!!)
                }
                if (employeeCode == null) {
                    setLoading(false)
                    tvInfo.text = "Funcionário não encontrado no ERP."
                    Toast.makeText(context, "Funcionário não encontrado no ERP.", Toast.LENGTH_LONG).show()
                    return@launch
                }

                tvInfo.text = "A registar presença..."

                val request = ClockRegisterRequest(
                    idempotency_key = UUID.randomUUID().toString(),
                    user_id = response.funcionario_id.toString(),
                    device_id = sessionManager.getOrCreateDeviceId(),
                    event_type = Constants.EVENT_AUTO,
                    recorded_at = DateTimeUtils.nowForApi(),
                    source = Constants.SOURCE_QR_CODE,
                    geo_lat = currentLocation?.latitude,
                    geo_lng = currentLocation?.longitude,
                    qr_token_id = null, // token já foi consumido na validação; poderíamos devolver o ID se necessário
                    registered_by = gestorUserId.toLongOrNull()
                )

                val registerResult = withContext(Dispatchers.IO) {
                    attendanceRepository.registerClock(request, employeeCodeOverride = employeeCode)
                }

                setLoading(false)

                when (registerResult) {
                    is AttendanceRepository.RegisterResult.Success -> {
                        tvInfo.text = "Presença registada com sucesso."
                        Toast.makeText(context, "Presença registada com sucesso.", Toast.LENGTH_SHORT).show()
                        parentFragmentManager.popBackStack()
                    }
                    is AttendanceRepository.RegisterResult.SavedOffline -> {
                        tvInfo.text = "Sem internet. Registo guardado localmente."
                        Toast.makeText(context, "Sem internet. Registo guardado e será sincronizado automaticamente.", Toast.LENGTH_LONG).show()
                        parentFragmentManager.popBackStack()
                    }
                    is AttendanceRepository.RegisterResult.Error -> {
                        tvInfo.text = registerResult.message
                        Toast.makeText(context, registerResult.message, Toast.LENGTH_LONG).show()
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                setLoading(false)
                tvInfo.text = "Falha ao registar presença."
                Toast.makeText(context, "Falha ao registar presença.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        btnScan.isEnabled = !isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
    }
}
