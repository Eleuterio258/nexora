package tech.e258tech.nexora_assiduidade.utils

import android.content.Context
import android.graphics.RectF
import android.util.Log
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facedetector.FaceDetector
import com.google.mediapipe.tasks.vision.facedetector.FaceDetectorResult

/**
 * Wrapper do MediaPipe FaceDetector (BlazeFace short-range) para deteccao
 * facial em tempo real na pre-visualizacao da camara.
 *
 * Usa o mesmo modelo (blaze_face_short_range.tflite, ~230KB, em assets/) que
 * o backend usa em `assiduidade_system_backend/app/services/biometric.py` —
 * garante que o feedback em tempo real no ecra (rosto centrado, bem
 * enquadrado) e consistente com a deteccao real feita no /biometric/verify,
 * sem substituir essa verificacao: o ecra so decide QUANDO capturar, quem
 * decide SE o rosto e reconhecido continua a ser o backend.
 */
class FaceDetectorHelper(
    context: Context,
    private val onResult: (result: FaceResult?) -> Unit,
    private val onError: (message: String) -> Unit,
) {

    data class FaceResult(
        val boundingBox: RectF,
        val score: Float,
        val imageWidth: Int,
        val imageHeight: Int,
    )

    private var detector: FaceDetector? = null

    init {
        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(MODEL_ASSET_PATH)
                .build()
            val options = FaceDetector.FaceDetectorOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setMinDetectionConfidence(MIN_DETECTION_CONFIDENCE)
                .setResultListener(::onDetectorResult)
                .setErrorListener { e -> onError(e.message ?: "Erro no detector facial") }
                .build()
            detector = FaceDetector.createFromOptions(context, options)
        } catch (e: Exception) {
            Log.e(TAG, "Falha ao carregar o modelo de deteccao facial", e)
            onError("Falha ao carregar o modelo de deteccao facial.")
        }
    }

    /** Deteta de forma assincrona; o resultado chega em [onResult] (thread do MediaPipe). */
    fun detectAsync(mpImage: MPImage, timestampMs: Long) {
        try {
            detector?.detectAsync(mpImage, timestampMs)
        } catch (e: Exception) {
            Log.w(TAG, "Frame descartado (detector ocupado): ${e.message}")
        }
    }

    private fun onDetectorResult(result: FaceDetectorResult, input: MPImage) {
        val detection = result.detections().firstOrNull()
        if (detection == null) {
            onResult(null)
            return
        }
        val bb = detection.boundingBox()
        onResult(
            FaceResult(
                boundingBox = RectF(bb.left.toFloat(), bb.top.toFloat(), bb.right.toFloat(), bb.bottom.toFloat()),
                score = detection.categories().firstOrNull()?.score() ?: 0f,
                imageWidth = input.width,
                imageHeight = input.height,
            )
        )
    }

    fun close() {
        detector?.close()
        detector = null
    }

    companion object {
        private const val TAG = "FaceDetectorHelper"
        private const val MODEL_ASSET_PATH = "blaze_face_short_range.tflite"
        private const val MIN_DETECTION_CONFIDENCE = 0.5f
    }
}
