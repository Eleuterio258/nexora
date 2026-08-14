package tech.e258tech.nexora_assiduidade.ui.gestor.funcionarios

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
import android.widget.FrameLayout
import android.widget.ImageView
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
import tech.e258tech.nexora_assiduidade.data.model.ConsentimentoLGPDRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.ui.funcionario.attendance.FaceOverlayView
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.BiometricErrorParser
import tech.e258tech.nexora_assiduidade.utils.FaceDetectorHelper
import tech.e258tech.nexora_assiduidade.utils.ImageUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Tela de enrollment facial de um funcionário, usada por gestores RH.
 *
 * Captura 3 fotos do rosto do funcionário e envia para o ERP, que faz proxy
 * para o FaceClock. O enrollment é guardado no tenant correcto e só é permitido
 * se existir consentimento LGPD activo e o método facial estiver activo.
 */
class EnrollFacialFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    companion object {
        private const val ARG_FUNCIONARIO_ID = "funcionario_id"
        private const val REQUIRED_CAPTURES = 3
        private const val MIN_SCORE = 0.6f
        private const val MIN_FACE_RATIO = 0.15f
        private const val MAX_FACE_RATIO = 0.55f
        private const val CENTER_TOLERANCE = 0.20f
        private const val CONSECUTIVE_GOOD_FRAMES_TO_CAPTURE = 10

        fun newInstance(funcionarioId: Long): EnrollFacialFragment {
            return EnrollFacialFragment().apply {
                arguments = Bundle().apply { putLong(ARG_FUNCIONARIO_ID, funcionarioId) }
            }
        }
    }

    private var funcionarioId: Long = 0L

    private lateinit var sessionManager: SessionManager

    private lateinit var btnStartCapture: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var ivPreview: ImageView
    private lateinit var previewView: PreviewView
    private lateinit var faceOverlayView: FaceOverlayView
    private lateinit var tvGuidance: TextView
    private lateinit var tvCameraPlaceholder: TextView
    private lateinit var tvProgress: TextView
    private lateinit var cameraContainer: FrameLayout

    private val captures = mutableListOf<Bitmap>()
    private var consecutiveGoodFrames = 0
    private var captureInProgress = false
    private var cameraStarted = false
    private var lastAnalyzedBitmap: Bitmap? = null

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
            setLoading(false)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        funcionarioId = arguments?.getLong(ARG_FUNCIONARIO_ID) ?: 0L
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_enroll_facial, container, false)
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

        btnStartCapture = view.findViewById(R.id.btnStartCapture)
        progressBar = view.findViewById(R.id.progressBar)
        ivPreview = view.findViewById(R.id.ivPreview)
        previewView = view.findViewById(R.id.previewView)
        faceOverlayView = view.findViewById(R.id.faceOverlayView)
        tvGuidance = view.findViewById(R.id.tvGuidance)
        tvCameraPlaceholder = view.findViewById(R.id.tvCameraPlaceholder)
        tvProgress = view.findViewById(R.id.tvProgress)
        cameraContainer = view.findViewById(R.id.cameraContainer)

        btnStartCapture.setOnClickListener { beginCapture() }

        view.findViewById<View>(R.id.ivBack).setOnClickListener {
            parentFragmentManager.popBackStack()
        }

        updateProgressText()
    }

    private fun beginCapture() {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getConsentimentoFuncionario(
                        ApiUtils.bearerToken(token),
                        funcionarioId
                    )
                }
                if (response.isSuccessful && response.body() != null) {
                    startCaptureFlow()
                } else {
                    showConsentDialog()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Toast.makeText(context, "Erro ao verificar consentimento: ${e.message}", Toast.LENGTH_LONG).show()
                setLoading(false)
            }
        }
    }

    private fun startCaptureFlow() {
        setLoading(false)
        captures.clear()
        consecutiveGoodFrames = 0
        captureInProgress = false
        cameraStarted = true
        ivPreview.visibility = View.GONE
        tvCameraPlaceholder.visibility = View.GONE
        tvGuidance.visibility = View.VISIBLE
        tvProgress.visibility = View.VISIBLE
        updateProgressText()
        btnStartCapture.isEnabled = false

        val hasCameraPermission = ContextCompat.checkSelfPermission(
            requireContext(), Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

        if (hasCameraPermission) {
            startCamera()
        } else {
            cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun showConsentDialog() {
        setLoading(false)
        androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Consentimento LGPD — Biometria Facial")
            .setMessage("Para cadastrar o rosto do funcionario e necessario o consentimento para tratamento de dados biometricos. O funcionario declara estar ciente de que as imagens serao usadas exclusivamente para registo de assiduidade, podendo ser revogadas a qualquer momento.")
            .setPositiveButton("Concordar e continuar") { _, _ -> registerConsentAndCapture() }
            .setNegativeButton("Cancelar", null)
            .setCancelable(false)
            .show()
    }

    private fun registerConsentAndCapture() {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida.", Toast.LENGTH_LONG).show()
            return
        }

        setLoading(true)
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.criarConsentimentoFuncionario(
                        ApiUtils.bearerToken(token),
                        ConsentimentoLGPDRequest(funcionarioId = funcionarioId)
                    )
                }
                if (response.isSuccessful) {
                    startCaptureFlow()
                } else {
                    val msg = ApiUtils.errorMessage(response)
                    Toast.makeText(context, "Erro ao registar consentimento: $msg", Toast.LENGTH_LONG).show()
                    setLoading(false)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Toast.makeText(context, "Erro de rede: ${e.message}", Toast.LENGTH_LONG).show()
                setLoading(false)
            }
        }
    }

    private fun startCamera() {
        faceDetectorHelper = FaceDetectorHelper(
            context = requireContext(),
            onResult = { result -> handleFaceResult(result) },
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
        if (captureInProgress) {
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
            // Frame ilegível — ignora.
        } finally {
            imageProxy.close()
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Int): Bitmap {
        if (degrees == 0) return bitmap
        val matrix = Matrix().apply { postRotate(degrees.toFloat()) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun handleFaceResult(result: FaceDetectorHelper.FaceResult?) {
        if (captureInProgress) return

        val wellFramed = result != null && isWellFramed(result)
        consecutiveGoodFrames = if (wellFramed) consecutiveGoodFrames + 1 else 0

        uiScope.launch {
            if (captureInProgress) return@launch
            faceOverlayView.update(result, wellFramed)
            tvGuidance.text = guidanceMessage(result, wellFramed)

            if (consecutiveGoodFrames >= CONSECUTIVE_GOOD_FRAMES_TO_CAPTURE) {
                captureFrame()
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
        if (result == null) return "Nenhum rosto detectado — posiciona o funcionario em frente a camara"
        if (wellFramed) return "Mantem parado... (${captures.size}/$REQUIRED_CAPTURES)"

        val imageArea = (result.imageWidth * result.imageHeight).toFloat()
        val faceRatio = if (imageArea > 0f) (result.boundingBox.width() * result.boundingBox.height()) / imageArea else 0f
        return when {
            faceRatio < MIN_FACE_RATIO -> "Aproxima um pouco"
            faceRatio > MAX_FACE_RATIO -> "Afasta um pouco"
            else -> "Centra o rosto no ecra"
        }
    }

    private fun captureFrame() {
        captureInProgress = true
        val bitmap = lastAnalyzedBitmap ?: run {
            captureInProgress = false
            return
        }

        captures.add(bitmap)
        updateProgressText()

        ivPreview.setImageBitmap(bitmap)
        ivPreview.visibility = View.VISIBLE

        if (captures.size >= REQUIRED_CAPTURES) {
            stopCamera()
            submitEnrollment()
            return
        }

        uiScope.launch {
            withContext(Dispatchers.Default) {
                delay(800)
            }
            consecutiveGoodFrames = 0
            captureInProgress = false
        }
    }

    private fun updateProgressText() {
        tvProgress.text = "Capturas: ${captures.size}/$REQUIRED_CAPTURES"
    }

    private fun stopCamera() {
        cameraProvider?.unbindAll()
        cameraProvider = null
        faceDetectorHelper?.close()
        faceDetectorHelper = null
        previewView.visibility = View.GONE
        faceOverlayView.clear()
        tvGuidance.visibility = View.GONE
    }

    private fun submitEnrollment() {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            Toast.makeText(context, "Sessao invalida.", Toast.LENGTH_LONG).show()
            setLoading(false)
            return
        }

        val captureParts = captures.mapIndexed { index, bitmap ->
            ImageUtils.bitmapToMultipartPart(
                bitmap = bitmap,
                formField = "captures",
                fileName = "capture_${index}.jpg"
            )
        }

        setLoading(true)

        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.enrollFacialFuncionarioMultipart(
                        ApiUtils.bearerToken(token),
                        ImageUtils.textToRequestBody(funcionarioId.toString()),
                        captureParts
                    )
                }

                if (response.isSuccessful && response.body() != null) {
                    Toast.makeText(
                        context,
                        "Rosto cadastrado com sucesso (template=${response.body()?.template_id}).",
                        Toast.LENGTH_LONG
                    ).show()
                    parentFragmentManager.popBackStack()
                } else {
                    val rawMsg = ApiUtils.errorMessage(response)
                    val parsed = BiometricErrorParser.parse(rawMsg)
                    showBiometricErrorDialog(parsed)
                    resetCapture()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Toast.makeText(context, "Erro de rede: ${e.message}", Toast.LENGTH_LONG).show()
                resetCapture()
            } finally {
                setLoading(false)
            }
        }
    }

    private fun resetCapture() {
        captures.clear()
        consecutiveGoodFrames = 0
        captureInProgress = false
        cameraStarted = false
        ivPreview.visibility = View.GONE
        tvCameraPlaceholder.visibility = View.VISIBLE
        tvProgress.visibility = View.GONE
        updateProgressText()
        btnStartCapture.isEnabled = true
    }

    private fun showBiometricErrorDialog(parsed: BiometricErrorParser.ParsedError) {
        context ?: return
        androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle("Não foi possível cadastrar o rosto")
            .setMessage(parsed.userMessage)
            .setPositiveButton("Tentar novamente") { dialog, _ -> dialog.dismiss() }
            .setNeutralButton("Ver detalhe técnico") { _, _ ->
                androidx.appcompat.app.AlertDialog.Builder(requireContext())
                    .setTitle("Detalhe técnico")
                    .setMessage(parsed.rawMessage)
                    .setPositiveButton("OK", null)
                    .show()
            }
            .setCancelable(false)
            .show()
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, outputStream)
        val bytes = outputStream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    private fun setLoading(isLoading: Boolean) {
        btnStartCapture.isEnabled = !isLoading && !cameraStarted
        progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
    }

    /**
     * Converte um frame RGBA_8888 da CameraX para Bitmap.
     * Copiado de FacialAttendanceFragment.
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
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        lastAnalyzedBitmap = if (rowPadding == 0) bitmap else Bitmap.createBitmap(bitmap, 0, 0, width, height)
        return lastAnalyzedBitmap!!
    }
}
