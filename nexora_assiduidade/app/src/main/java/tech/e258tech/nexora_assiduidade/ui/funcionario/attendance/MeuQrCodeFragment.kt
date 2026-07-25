package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.graphics.Bitmap
import android.os.Bundle
import android.os.CountDownTimer
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.zxing.BarcodeFormat
import com.journeyapps.barcodescanner.BarcodeEncoder
import java.time.Instant
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Funcionário mostra o seu QR Code pessoal para o gestor ler.
 */
class MeuQrCodeFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager

    private lateinit var ivQrCode: ImageView
    private lateinit var tvCountdown: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var btnRenovar: Button

    private var countdownTimer: CountDownTimer? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_meu_qr_code, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        countdownTimer?.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        ivQrCode = view.findViewById(R.id.ivQrCode)
        tvCountdown = view.findViewById(R.id.tvCountdown)
        progressBar = view.findViewById(R.id.progressBar)
        btnRenovar = view.findViewById(R.id.btnRenovar)

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        btnRenovar.setOnClickListener {
            carregarQr()
        }

        carregarQr()
    }

    private fun carregarQr() {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessão inválida. Faça login novamente.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        countdownTimer?.cancel()

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getMyQr(ApiUtils.bearerToken(token))
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvCountdown.text = ApiUtils.errorMessage(response)
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
                    tvCountdown.text = "Erro ao gerar imagem do QR Code."
                    setLoading(false)
                    return@launch
                }

                ivQrCode.setImageBitmap(bitmap)

                val expiresAt = try {
                    Instant.parse(body.expires_at)
                } catch (_: Exception) {
                    Instant.now().plusSeconds(60)
                }
                startCountdown(expiresAt)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvCountdown.text = "Falha ao carregar QR Code."
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
            }
        }.start()
    }

    private fun setLoading(isLoading: Boolean) {
        btnRenovar.isEnabled = !isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        ivQrCode.visibility = if (isLoading) View.GONE else View.VISIBLE
    }
}
