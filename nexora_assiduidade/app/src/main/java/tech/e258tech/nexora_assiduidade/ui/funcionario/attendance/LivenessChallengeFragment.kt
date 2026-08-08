package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Bundle
import android.os.SystemClock
import android.util.Base64
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.google.mediapipe.framework.image.BitmapImageBuilder
import java.io.ByteArrayOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.FacialPontoDados
import tech.e258tech.nexora_assiduidade.data.model.LivenessChallengeRequest
import tech.e258tech.nexora_assiduidade.data.model.LivenessVerifyRequest
import tech.e258tech.nexora_assiduidade.data.model.MarcarPontoFacialSelfServiceRequest
import tech.e258tech.nexora_assiduidade.data.model.response.LivenessChallengeResponse
import tech.e258tech.nexora_assiduidade.data.model.response.LivenessVerifyResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.FaceDetectorHelper
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de prova de vida ativa (liveness challenge) para marcação de ponto.
 *
 * Fluxo:
 * 1. Pedir desafio ao ERP (→ FaceClock /api/v1/liveness/challenge).
 * 2. Mostrar instrução (piscar, sorrir ou virar o rosto).
 * 3. Gravar frames da câmara frontal durante alguns segundos.
 * 4. Enviar frames para validação (→ FaceClock /api/v1/liveness/verify).
 * 5. Se houver match, usar o verification_token para marcar o ponto.
 */
class LivenessChallengeFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager

    private lateinit var btnStart: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var previewView: PreviewView
    private lateinit var faceOverlayView: FaceOverlayView
    private lateinit var tvInstruction: TextView

    private var challenge: LivenessChallengeResponse? = null
    private var recording = false
    private val frames = mutableListOf<String>()

    private var cameraProvider: ProcessCameraProvider? = null
    private var faceDetectorHelper: FaceDetectorHelper? = null
    private lateinit var cameraExecutor: ExecutorService

    private val cameraPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            startCamera()
        } else {
            Toast.makeText(context, "Permissao de camara necessaria.", Toast.LENGTH_LONG).show()
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        return inflater.inflate(R.layout.fragment_liveness_challenge, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        stopCamera()
        if (::cameraExecutor.isInitialized) {
            cameraExecutor.shutdown()
        }
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        cameraExecutor = Executors.newSingleThreadExecutor()

        btnStart = view.findViewById(R.id.btnStart)
        progressBar = view.findViewById(R.id.progressBar)
        previewView = view.findViewById(R.id.previewView)
        faceOverlayView = view.findViewById(R.id.faceOverlayView)
        tvInstruction = view.findViewById(R.id.tvInstruction)

        btnStart.setOnClickListener { beginChallenge() }
        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        val hasCameraPermission = ContextCompat.checkSelfPermission(
            requireContext(), Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
        if (hasCameraPermission) {
            startCamera()
        } else {
            cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun beginChallenge() {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.livenessChallenge(
                        ApiUtils.bearerToken(token),
                        LivenessChallengeRequest(user_id = sessionManager.getUserId() ?: "")
                    )
                }
                if (response.isSuccessful && response.body() != null) {
                    challenge = response.body()
                    startRecording()
                } else {
                    setLoading(false)
                    Toast.makeText(
                        context,
                        "Erro ao pedir desafio: ${ApiUtils.errorMessage(response)}",
                        Toast.LENGTH_LONG
                    ).show()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                setLoading(false)
                Toast.makeText(context, "Erro de rede: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun startRecording() {
        val prompt = challenge?.prompt ?: "Siga a instrucao"
        tvInstruction.text = prompt
        btnStart.isEnabled = false
        recording = true
        frames.clear()

        uiScope.launch {
            delay(RECORDING_DURATION_MS)
            recording = false
            submitVerify()
        }
    }

    private fun startCamera() {
        faceDetectorHelper = FaceDetectorHelper(
            context = requireContext(),
            onResult = { result ->
                uiScope.launch { faceOverlayView.update(result, result != null) }
            },
            onError = { message ->
                uiScope.launch { Toast.makeText(context, message, Toast.LENGTH_LONG).show() }
            }
        )

        previewView.visibility = View.VISIBLE
        val providerFuture = ProcessCameraProvider.getInstance(requireContext())
        providerFuture.addListener({
            cameraProvider = providerFuture.get()
            bindCameraUseCases()
        }, ContextCompat.getMainExecutor(requireContext()))
    }

    private fun bindCameraUseCases() {
        val provider = cameraProvider ?: return

        val preview = Preview.Builder().build().also {
            it.surfaceProvider = previewView.surfaceProvider
        }

        val imageAnalysis = ImageAnalysis.Builder()
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
            .also {
                it.setAnalyzer(cameraExecutor, ::analyzeFrame)
            }

        try {
            provider.unbindAll()
            provider.bindToLifecycle(
                viewLifecycleOwner,
                CameraSelector.DEFAULT_FRONT_CAMERA,
                preview,
                imageAnalysis
            )
        } catch (e: Exception) {
            Toast.makeText(context, "Erro ao iniciar a camara: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun analyzeFrame(imageProxy: ImageProxy) {
        try {
            if (recording && frames.size < MAX_FRAMES) {
                val bitmap = imageProxy.toBitmap()
                val rotated = rotateBitmap(bitmap, imageProxy.imageInfo.rotationDegrees)
                frames.add(bitmapToBase64(rotated))
            }
            if (recording) {
                val bitmap = imageProxy.toBitmap()
                val rotated = rotateBitmap(bitmap, imageProxy.imageInfo.rotationDegrees)
                val mpImage = BitmapImageBuilder(rotated).build()
                faceDetectorHelper?.detectAsync(mpImage, SystemClock.uptimeMillis())
            }
        } catch (e: Exception) {
            // Ignora frames ilegíveis.
        } finally {
            imageProxy.close()
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Int): Bitmap {
        if (degrees == 0) return bitmap
        val matrix = Matrix().apply { postRotate(degrees.toFloat()) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, outputStream)
        val bytes = outputStream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    private fun submitVerify() {
        val token = sessionManager.getToken()
        val currentChallenge = challenge
        if (token.isNullOrBlank() || currentChallenge == null || frames.isEmpty()) {
            setLoading(false)
            Toast.makeText(context, "Dados insuficientes para validar o desafio.", Toast.LENGTH_LONG).show()
            return
        }

        uiScope.launch {
            val verifyPair: Pair<LivenessVerifyResponse?, String?> = withContext(Dispatchers.IO) {
                try {
                    val deviceId = sessionManager.getOrCreateDeviceId()
                    val response = RetrofitClient.erpApiService.livenessVerify(
                        ApiUtils.bearerToken(token),
                        LivenessVerifyRequest(
                            challenge_id = currentChallenge.challenge_id ?: "",
                            device_id = deviceId,
                            frames_base64 = frames.toList()
                        )
                    )
                    if (response.isSuccessful && response.body() != null) {
                        response.body()!! to null
                    } else {
                        null to ApiUtils.errorMessage(response)
                    }
                } catch (e: Exception) {
                    null to (e.message ?: "Erro na validacao do desafio")
                }
            }

            val verifyResponse = verifyPair.first
            val errorMessage = verifyPair.second

            if (verifyResponse == null) {
                setLoading(false)
                Toast.makeText(context, errorMessage ?: "Erro na validacao", Toast.LENGTH_LONG).show()
                return@launch
            }

            if (verifyResponse.match != true) {
                setLoading(false)
                Toast.makeText(
                    context,
                    "Desafio falhou: ${verifyResponse.reason ?: "tenta novamente"}",
                    Toast.LENGTH_LONG
                ).show()
                return@launch
            }

            val verificationToken = verifyResponse.verification_token
            if (verificationToken.isNullOrBlank()) {
                setLoading(false)
                Toast.makeText(context, "Comprovativo facial em falta.", Toast.LENGTH_LONG).show()
                return@launch
            }

            val registerResponse = withContext(Dispatchers.IO) {
                RetrofitClient.erpApiService.marcarPontoFacialSelfService(
                    ApiUtils.bearerToken(token),
                    MarcarPontoFacialSelfServiceRequest(
                        dados = FacialPontoDados(
                            verification_token = verificationToken,
                            device_id = sessionManager.getOrCreateDeviceId()
                        )
                    )
                )
            }

            setLoading(false)
            if (registerResponse.isSuccessful && registerResponse.body() != null) {
                Toast.makeText(context, "Registo de presenca realizado com sucesso.", Toast.LENGTH_SHORT).show()
                parentFragmentManager.popBackStack()
            } else {
                Toast.makeText(context, ApiUtils.errorMessage(registerResponse), Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun stopCamera() {
        cameraProvider?.unbindAll()
        cameraProvider = null
        faceDetectorHelper?.close()
        faceDetectorHelper = null
    }

    private fun setLoading(isLoading: Boolean) {
        btnStart.isEnabled = !isLoading
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
    }

    companion object {
        private const val RECORDING_DURATION_MS = 3500L
        private const val MAX_FRAMES = 16
    }
}

private fun ImageProxy.toBitmap(): Bitmap {
    val plane = planes[0]
    val buffer = plane.buffer
    val pixelStride = plane.pixelStride
    val rowStride = plane.rowStride
    val rowPadding = rowStride - pixelStride * width

    val bitmap = Bitmap.createBitmap(
        width + rowPadding / pixelStride,
        height,
        Bitmap.Config.ARGB_8888
    )
    bitmap.copyPixelsFromBuffer(buffer)
    return if (rowPadding == 0) bitmap else Bitmap.createBitmap(bitmap, 0, 0, width, height)
}
