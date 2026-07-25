package tech.e258tech.nexora_assiduidade.ui.gestor.qrcode

import android.graphics.Bitmap
import android.os.Bundle
import android.os.CountDownTimer
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.zxing.BarcodeFormat
import com.journeyapps.barcodescanner.BarcodeEncoder
import java.time.Instant
import java.time.format.DateTimeFormatter
import java.util.UUID
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.QRGenerateDeviceRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Gestor gera um QR Code fixo para os funcionários lerem.
 */
class GestorGerarQrFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var etLocationId: EditText
    private lateinit var etDuracao: EditText
    private lateinit var btnGerar: Button
    private lateinit var ivQrCode: ImageView
    private lateinit var tvCountdown: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var tvStatus: TextView

    private var countdownTimer: CountDownTimer? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.gestor_gerar_qr, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        countdownTimer?.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        etLocationId = view.findViewById(R.id.etLocationId)
        etDuracao = view.findViewById(R.id.etDuracao)
        btnGerar = view.findViewById(R.id.btnGerar)
        ivQrCode = view.findViewById(R.id.ivQrCode)
        tvCountdown = view.findViewById(R.id.tvCountdown)
        progressBar = view.findViewById(R.id.progressBar)
        tvStatus = view.findViewById(R.id.tvStatus)

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        btnGerar.setOnClickListener {
            gerarQr()
        }
    }

    private fun gerarQr() {
        val token = SessionManager(requireContext()).getToken()
        if (token.isNullOrBlank()) {
            tvStatus.text = "Sessão inválida. Faça login novamente."
            return
        }

        val locationId = etLocationId.text?.toString()?.trim()?.takeIf { it.isNotBlank() }
        val duracao = etDuracao.text?.toString()?.toIntOrNull() ?: qrDuracaoPadraoSegundos
        if (duracao < 60 || duracao > 300) {
            Toast.makeText(context, "Duração deve estar entre 60 e 300 segundos", Toast.LENGTH_SHORT).show()
            return
        }

        setLoading(true)
        countdownTimer?.cancel()

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.generateQr(
                        ApiUtils.bearerToken(token),
                        QRGenerateDeviceRequest(location_id = locationId, duracao_segundos = duracao)
                    )
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvStatus.text = ApiUtils.errorMessage(response)
                    setLoading(false)
                    return@launch
                }

                val body = response.body()!!
                val bitmap = withContext(Dispatchers.IO) {
                    try {
                        BarcodeEncoder().encodeBitmap(body.qr_code, BarcodeFormat.QR_CODE, 512, 512)
                    } catch (e: Exception) {
                        null
                    }
                }

                if (bitmap == null) {
                    tvStatus.text = "Erro ao gerar imagem do QR Code."
                    setLoading(false)
                    return@launch
                }

                ivQrCode.setImageBitmap(bitmap)
                ivQrCode.visibility = View.VISIBLE
                tvCountdown.visibility = View.VISIBLE
                tvStatus.text = "QR Code gerado. Válido por $duracao segundos."

                val expiresAt = try {
                    Instant.parse(body.expires_at)
                } catch (_: Exception) {
                    Instant.now().plusSeconds(duracao.toLong())
                }
                startCountdown(expiresAt)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvStatus.text = "Falha ao gerar QR Code."
            } finally {
                if (isAdded) setLoading(false)
            }
        }
    }

    private fun startCountdown(expiresAt: Instant) {
        countdownTimer?.cancel()
        val remaining = expiresAt.toEpochMilli() - System.currentTimeMillis()
        if (remaining <= 0) {
            tvCountdown.text = "Expirado"
            return
        }
        countdownTimer = object : CountDownTimer(remaining, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = millisUntilFinished / 1000
                tvCountdown.text = "Expira em ${seconds}s"
            }

            override fun onFinish() {
                tvCountdown.text = "Expirado"
                ivQrCode.visibility = View.GONE
            }
        }.start()
    }

    private fun setLoading(isLoading: Boolean) {
        btnGerar.isEnabled = !isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
    }

    companion object {
        private const val qrDuracaoPadraoSegundos = 60
    }
}
