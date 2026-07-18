package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.RectF
import android.os.Bundle
import android.os.SystemClock
import android.util.Base64
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.RadioGroup
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
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
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
import tech.e258tech.nexora_assiduidade.utils.FaceDetectorHelper
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de registo de presenca por reconhecimento facial.
 *
 * Preview da camara frontal em tempo real com deteccao facial no dispositivo
 * (MediaPipe FaceDetector / BlazeFace short-range) — o overlay verde e o
 * "Mantem-te parado..." servem so para guiar o utilizador a um bom
 * enquadramento e disparar a captura automatica; quem decide se o rosto e
 * reconhecido continua a ser exclusivamente o backend, em /biometric/verify.
 */
class FacialAttendanceFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var sessionManager: SessionManager
    private lateinit var attendanceRepository: AttendanceRepository

    private lateinit var radioGroupType: RadioGroup
    private lateinit var btnCapture: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var ivCapturedFace: ImageView
    private lateinit var previewView: PreviewView
    private lateinit var faceOverlayView: FaceOverlayView
    private lateinit var tvGuidance: TextView
    private lateinit var tvCameraPlaceholder: TextView
    private lateinit var cameraContainer: FrameLayout

    private var lastCapturedBase64: String? = null
    private var lastAnalyzedBitmap: Bitmap? = null
    private var consecutiveGoodFrames = 0
    private var captureTriggered = false

    private var cameraProvider: ProcessCameraProvider? = null
    private var faceDetectorHelper: FaceDetectorHelper? = null
    private lateinit var cameraExecutor: ExecutorService

    private val cameraPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            startCamera()
        } else {
            Toast.makeText(context, "Permissao de camara necessaria para captura facial.", Toast.LENGTH_LONG).show()
            setLoading(false)
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
        stopCamera()
        if (::cameraExecutor.isInitialized) {
            cameraExecutor.shutdown()
        }
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())
        attendanceRepository = AttendanceRepository(requireContext())
        cameraExecutor = Executors.newSingleThreadExecutor()

        radioGroupType = view.findViewById(R.id.radioGroupType)
        btnCapture = view.findViewById(R.id.btnCapture)
        progressBar = view.findViewById(R.id.progressBar)
        ivCapturedFace = view.findViewById(R.id.ivCapturedFace)
        previewView = view.findViewById(R.id.previewView)
        faceOverlayView = view.findViewById(R.id.faceOverlayView)
        tvGuidance = view.findViewById(R.id.tvGuidance)
        tvCameraPlaceholder = view.findViewById(R.id.tvCameraPlaceholder)
        cameraContainer = view.findViewById(R.id.cameraContainer)

        btnCapture.setOnClickListener {
            val selectedId = radioGroupType.checkedRadioButtonId
            if (selectedId == -1) {
                Toast.makeText(context, "Selecione Entrada ou Saida", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            beginCapture()
        }
    }

    private fun beginCapture() {
        resetCaptureState()
        ivCapturedFace.visibility = View.GONE
        tvCameraPlaceholder.visibility = View.GONE
        tvGuidance.visibility = View.VISIBLE
        tvGuidance.text = "A iniciar camara..."
        btnCapture.isEnabled = false

        val hasCameraPermission = ContextCompat.checkSelfPermission(
            requireContext(), Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

        if (hasCameraPermission) {
            startCamera()
        } else {
            cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun resetCaptureState() {
        consecutiveGoodFrames = 0
        captureTriggered = false
        lastCapturedBase64 = null
        lastAnalyzedBitmap = null
    }

    private fun startCamera() {
        faceDetectorHelper = FaceDetectorHelper(
            context = requireContext(),
            onResult = { result -> handleFaceResult(result) },
            onError = { message ->
                uiScope.launch { Toast.makeText(context, message, Toast.LENGTH_LONG).show() }
            },
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
                imageAnalysis,
            )
        } catch (e: Exception) {
            Toast.makeText(context, "Erro ao iniciar a camara: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun analyzeFrame(imageProxy: ImageProxy) {
        if (captureTriggered) {
            imageProxy.close()
            return
        }
        try {
            val bitmap = imageProxy.toBitmap()
            val rotated = rotateBitmap(bitmap, imageProxy.imageInfo.rotationDegrees)
            lastAnalyzedBitmap = rotated
            val mpImage = BitmapImageBuilder(rotated).build()
            faceDetectorHelper?.detectAsync(mpImage, SystemClock.uptimeMillis())
        } catch (e: Exception) {
            // Frame ilegivel/corrompido — ignora e tenta o proximo.
        } finally {
            imageProxy.close()
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Int): Bitmap {
        if (degrees == 0) return bitmap
        val matrix = Matrix().apply { postRotate(degrees.toFloat()) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    /** Chamado na thread do MediaPipe — so mexe em UI via [uiScope] (Dispatchers.Main). */
    private fun handleFaceResult(result: FaceDetectorHelper.FaceResult?) {
        if (captureTriggered) return

        val wellFramed = result != null && isWellFramed(result)
        consecutiveGoodFrames = if (wellFramed) consecutiveGoodFrames + 1 else 0

        uiScope.launch {
            if (captureTriggered) return@launch
            faceOverlayView.update(result, wellFramed)
            tvGuidance.text = guidanceMessage(result, wellFramed)

            if (consecutiveGoodFrames >= CONSECUTIVE_GOOD_FRAMES_TO_CAPTURE) {
                triggerAutoCapture()
            }
        }
    }

    private fun isWellFramed(result: FaceDetectorHelper.FaceResult): Boolean {
        if (result.score < MIN_SCORE) return false

        val imageArea = (result.imageWidth * result.imageHeight).toFloat()
        if (imageArea <= 0f) return false
        val box = result.boundingBox
        val faceRatio = (box.width() * box.height()) / imageArea
        if (faceRatio < MIN_FACE_RATIO || faceRatio > MAX_FACE_RATIO) return false

        val faceCenterX = box.centerX() / result.imageWidth
        val faceCenterY = box.centerY() / result.imageHeight
        val offCenterX = kotlin.math.abs(faceCenterX - 0.5f)
        val offCenterY = kotlin.math.abs(faceCenterY - 0.5f)
        return offCenterX <= CENTER_TOLERANCE && offCenterY <= CENTER_TOLERANCE
    }

    private fun guidanceMessage(result: FaceDetectorHelper.FaceResult?, wellFramed: Boolean): String {
        if (result == null) return "Nenhum rosto detectado — posiciona-te em frente a camara"
        if (wellFramed) return "Mantem-te parado..."

        val imageArea = (result.imageWidth * result.imageHeight).toFloat()
        val faceRatio = if (imageArea > 0f) (result.boundingBox.width() * result.boundingBox.height()) / imageArea else 0f
        return when {
            faceRatio < MIN_FACE_RATIO -> "Aproxima-te um pouco"
            faceRatio > MAX_FACE_RATIO -> "Afasta-te um pouco"
            else -> "Centra o rosto no ecra"
        }
    }

    private fun triggerAutoCapture() {
        captureTriggered = true
        val bitmap = lastAnalyzedBitmap ?: return

        previewView.visibility = View.GONE
        faceOverlayView.clear()
        tvGuidance.visibility = View.GONE
        ivCapturedFace.setImageBitmap(bitmap)
        ivCapturedFace.visibility = View.VISIBLE
        lastCapturedBase64 = bitmapToBase64(bitmap)

        stopCamera()

        val selectedId = radioGroupType.checkedRadioButtonId
        val eventType = if (selectedId == R.id.radioEntrada) Constants.EVENT_ENTRY else Constants.EVENT_EXIT
        verifyAndRegister(eventType)
    }

    private fun stopCamera() {
        cameraProvider?.unbindAll()
        cameraProvider = null
        faceDetectorHelper?.close()
        faceDetectorHelper = null
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

    companion object {
        private const val MIN_SCORE = 0.6f
        private const val MIN_FACE_RATIO = 0.15f
        private const val MAX_FACE_RATIO = 0.55f
        private const val CENTER_TOLERANCE = 0.20f
        private const val CONSECUTIVE_GOOD_FRAMES_TO_CAPTURE = 15
    }
}

/**
 * Converte um frame RGBA_8888 da CameraX (ImageAnalysis) para Bitmap.
 * So valido quando `ImageAnalysis.setOutputImageFormat(OUTPUT_IMAGE_FORMAT_RGBA_8888)`
 * foi configurado — nesse modo o plano unico ja vem no layout que o Bitmap espera.
 */
private fun ImageProxy.toBitmap(): Bitmap {
    val plane = planes[0]
    val buffer = plane.buffer
    val pixelStride = plane.pixelStride
    val rowStride = plane.rowStride
    val rowPadding = rowStride - pixelStride * width

    val bitmap = Bitmap.createBitmap(
        width + rowPadding / pixelStride,
        height,
        Bitmap.Config.ARGB_8888,
    )
    bitmap.copyPixelsFromBuffer(buffer)
    return if (rowPadding == 0) bitmap else Bitmap.createBitmap(bitmap, 0, 0, width, height)
}
