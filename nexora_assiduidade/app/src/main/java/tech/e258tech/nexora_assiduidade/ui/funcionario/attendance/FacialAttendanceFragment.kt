package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.provider.MediaStore
import android.util.Base64
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.RadioGroup
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.Fragment
import java.io.ByteArrayOutputStream
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.FaceVerifyRequest
import tech.e258tech.nexora_assiduidade.data.model.response.FaceVerifyResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.data.repository.AttendanceRepository
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.Constants
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por reconhecimento facial.
 *
 * Captura uma foto com a camara do dispositivo, envia para o backend
 * /biometric/verify e, se reconhecido, regista o ponto.
 */
class FacialAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
    private lateinit var attendanceRepository: AttendanceRepository

    private lateinit var radioGroupType: RadioGroup
    private lateinit var btnCapture: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var ivCapturedFace: ImageView

    private var lastCapturedBase64: String? = null

    private val cameraLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val bitmap = result.data?.extras?.get("data") as? Bitmap
            if (bitmap != null) {
                ivCapturedFace.setImageBitmap(bitmap)
                ivCapturedFace.visibility = View.VISIBLE
                lastCapturedBase64 = bitmapToBase64(bitmap)

                val selectedId = radioGroupType.checkedRadioButtonId
                if (selectedId != -1) {
                    val eventType = if (selectedId == R.id.radioEntrada) {
                        Constants.EVENT_ENTRY
                    } else {
                        Constants.EVENT_EXIT
                    }
                    verifyAndRegister(eventType)
                }
            } else {
                Toast.makeText(context, "Falha ao capturar foto.", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.funcionario_facial_attendance, container, false)
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
        btnCapture = view.findViewById(R.id.btnCapture)
        progressBar = view.findViewById(R.id.progressBar)
        ivCapturedFace = view.findViewById(R.id.ivCapturedFace)

        btnCapture.setOnClickListener {
            val selectedId = radioGroupType.checkedRadioButtonId
            if (selectedId == -1) {
                Toast.makeText(context, "Selecione Entrada ou Saida", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            openCamera()
        }
    }

    private fun openCamera() {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (intent.resolveActivity(requireActivity().packageManager) != null) {
            cameraLauncher.launch(intent)
        } else {
            Toast.makeText(context, "Camara nao disponivel.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun verifyAndRegister(eventType: String) {
        val userId = sessionManager.getUserId()
        val token = sessionManager.getToken()
        val imageBase64 = lastCapturedBase64

        if (userId.isNullOrBlank() || token.isNullOrBlank() || imageBase64.isNullOrBlank()) {
            Toast.makeText(context, "Dados insuficientes para verificacao.", Toast.LENGTH_LONG)
                .show()
            return
        }

        setLoading(true)

        uiScope.launch {
            val verifyPair: Pair<FaceVerifyResponse?, String?> = withContext(Dispatchers.IO) {
                try {
                    val response = RetrofitClient.assiduidadeApiService.verifyFace(
                        ApiUtils.bearerToken(token),
                        FaceVerifyRequest(
                            user_id = userId,
                            device_id = sessionManager.getOrCreateDeviceId(),
                            image_base64 = imageBase64
                        )
                    )
                    if (response.isSuccessful && response.body() != null) {
                        response.body()!! to null
                    } else {
                        null to ApiUtils.errorMessage(response)
                    }
                } catch (e: Exception) {
                    null to (e.message ?: "Erro na verificacao facial")
                }
            }

            val verifyResponse = verifyPair.first
            val errorMessage = verifyPair.second

            if (verifyResponse == null) {
                setLoading(false)
                Toast.makeText(context, errorMessage ?: "Erro na verificacao facial", Toast.LENGTH_LONG).show()
                return@launch
            }

            if (!verifyResponse.match) {
                setLoading(false)
                Toast.makeText(
                    context,
                    "Rosto nao reconhecido. ${verifyResponse.reason ?: ""}",
                    Toast.LENGTH_LONG
                ).show()
                return@launch
            }

            val request = ClockRegisterRequest(
                idempotency_key = UUID.randomUUID().toString(),
                user_id = userId,
                device_id = sessionManager.getOrCreateDeviceId(),
                event_type = eventType,
                recorded_at = DateTimeUtils.nowForApi(),
                source = Constants.SOURCE_FACIAL,
                confidence_score = verifyResponse.confidence_score,
                liveness_score = verifyResponse.liveness_score
            )

            val registerResult = withContext(Dispatchers.IO) {
                attendanceRepository.registerClock(request)
            }

            setLoading(false)
            val action = if (eventType == Constants.EVENT_ENTRY) "entrada" else "saida"

            when (registerResult) {
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
                    Toast.makeText(context, registerResult.message, Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, outputStream)
        val bytes = outputStream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    private fun setLoading(isLoading: Boolean) {
        btnCapture.isEnabled = !isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
    }
}
