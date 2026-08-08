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
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.MarcarPontoGestorAssiduidadeRequest
import tech.e258tech.nexora_assiduidade.data.model.QRValidateDeviceRequest
import tech.e258tech.nexora_assiduidade.data.model.response.QRValidateDeviceResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.common.CaptureActivityPortrait
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Gestor lê o QR Code pessoal do funcionário e regista a presença em nome dele.
 */
class GestorLerQrFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
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
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessão inválida. Faça login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        tvInfo.text = "A validar QR Code..."

        uiScope.launch {
            try {
                val validateResult: Pair<QRValidateDeviceResponse?, String?> = withContext(Dispatchers.IO) {
                    try {
                        val response = RetrofitClient.erpApiService.validateQrSelfService(
                            ApiUtils.bearerToken(token),
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

                if (response == null || !response.valid || response.funcionario_id == null) {
                    setLoading(false)
                    tvInfo.text = error ?: "QR Code inválido ou não vinculado a funcionário."
                    Toast.makeText(context, error ?: "QR Code inválido ou não vinculado a funcionário.", Toast.LENGTH_LONG).show()
                    return@launch
                }

                tvInfo.text = "A registar presença..."

                val registerRequest = MarcarPontoGestorAssiduidadeRequest(
                    funcionario_id = response.funcionario_id,
                    data = DateTimeUtils.todayForApi(),
                    hora = DateTimeUtils.currentTimeShortForApi(),
                    tipo_evento_codigo = "", // vazio para o ERP inferir entrada/saída pela paridade do dia
                    latitude = currentLocation?.latitude,
                    longitude = currentLocation?.longitude,
                    observacoes = "Registo via QR Code lido por gestor"
                )

                val registerResponse = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.marcarPontoGestor(
                        ApiUtils.bearerToken(token),
                        registerRequest
                    )
                }

                setLoading(false)

                if (registerResponse.isSuccessful) {
                    tvInfo.text = "Presença registada com sucesso."
                    Toast.makeText(context, "Presença registada com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                } else {
                    val message = ApiUtils.errorMessage(registerResponse)
                    tvInfo.text = message
                    Toast.makeText(context, message, Toast.LENGTH_LONG).show()
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
