package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.Manifest
import android.content.pm.PackageManager
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
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.MarcarPontoQrSelfServiceRequest
import tech.e258tech.nexora_assiduidade.data.model.QrPontoDados
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.common.CaptureActivityPortrait
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por leitura de QR Code.
 *
 * Usa ZXing para ler um QR Code e envia-o para
 * `POST /api/self-service/assiduidade/ponto`. O ERP valida e consome o token
 * atomicamente antes de criar o evento do colaborador autenticado.
 */
class QrCodeAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager

    private lateinit var btnScan: Button
    private lateinit var tvQrInfo: TextView
    private lateinit var progressBar: ProgressBar

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

        btnScan = view.findViewById(R.id.btnScan)
        tvQrInfo = view.findViewById(R.id.tvQrInfo)
        progressBar = view.findViewById(R.id.progressBar)

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

    private fun startScan() {
        val options = ScanOptions()
            .setPrompt("Aproxime o QR Code do leitor")
            .setBeepEnabled(true)
            .setOrientationLocked(false)
            .setCaptureActivity(CaptureActivityPortrait::class.java)
        scanLauncher.launch(options)
    }

    private fun validateQrAndRegister(qrCode: String) {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida. Faca login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        tvQrInfo.text = "A validar QR Code..."

        uiScope.launch {
            try {
                val request = MarcarPontoQrSelfServiceRequest(
                    dados = QrPontoDados(qr_code = qrCode)
                )
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.marcarPontoQrSelfService(
                        ApiUtils.bearerToken(token),
                        request
                    )
                }

                if (response.isSuccessful) {
                    tvQrInfo.text = "Registo de presença realizado com sucesso."
                    Toast.makeText(context, "Registo de presença realizado com sucesso.", Toast.LENGTH_SHORT).show()
                    parentFragmentManager.popBackStack()
                } else {
                    tvQrInfo.text = "QR Code inválido ou expirado."
                    Toast.makeText(context, ApiUtils.errorMessage(response), Toast.LENGTH_LONG).show()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                tvQrInfo.text = "Falha ao comunicar com o ERP. Tente novamente."
                Toast.makeText(context, "Falha ao comunicar com o ERP.", Toast.LENGTH_LONG).show()
            } finally {
                if (isAdded) setLoading(false)
            }
        }
    }

    private fun setLoading(isLoading: Boolean) {
        btnScan.isEnabled = !isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
    }
}
