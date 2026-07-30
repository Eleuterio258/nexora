package com.example.nexora

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.Handler
import android.os.Looper
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facedetector.FaceDetector
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Ponte MethodChannel/EventChannel para o MediaPipe FaceDetector (BlazeFace
 * short-range) nativo — o pacote Flutter oficial não expõe MediaPipe Tasks,
 * só ML Kit, por isso corremos o mesmo detector do nexora_assiduidade
 * (blaze_face_short_range.tflite) directamente aqui em Kotlin.
 *
 * Espelha tech.e258tech.nexora_assiduidade.utils.FaceDetectorHelper: mesmo
 * modelo, mesmo RunningMode.LIVE_STREAM, mesmo MIN_DETECTION_CONFIDENCE.
 */
class MediaPipeFaceDetectorHandler(
    private val context: Context,
    private val methodChannel: MethodChannel,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private var detector: FaceDetector? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        methodChannel.setMethodCallHandler(this)
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                try {
                    initDetector()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("INIT_FAILED", e.message, null)
                }
            }
            "detect" -> {
                try {
                    detectFrame(call, result)
                } catch (e: Exception) {
                    result.error("DETECT_FAILED", e.message, null)
                }
            }
            "close" -> {
                detector?.close()
                detector = null
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun initDetector() {
        detector?.close()
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(MODEL_ASSET_PATH)
            .build()
        val options = FaceDetector.FaceDetectorOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setMinDetectionConfidence(MIN_DETECTION_CONFIDENCE)
            .setResultListener { faceResult, _ ->
                val detection = faceResult.detections().firstOrNull()
                val payload = if (detection == null) {
                    mapOf("hasFace" to false)
                } else {
                    val bb = detection.boundingBox()
                    mapOf(
                        "hasFace" to true,
                        "left" to bb.left.toDouble(),
                        "top" to bb.top.toDouble(),
                        "right" to bb.right.toDouble(),
                        "bottom" to bb.bottom.toDouble(),
                        "score" to (detection.categories().firstOrNull()?.score()?.toDouble() ?: 0.0),
                        "imageWidth" to lastImageWidth,
                        "imageHeight" to lastImageHeight,
                    )
                }
                mainHandler.post { eventSink?.success(payload) }
            }
            .setErrorListener { e ->
                mainHandler.post {
                    methodChannel.invokeMethod("onError", e.message ?: "Erro no detector facial")
                }
            }
            .build()
        detector = FaceDetector.createFromOptions(context, options)
    }

    private var lastImageWidth: Int = 0
    private var lastImageHeight: Int = 0

    private fun detectFrame(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val width = call.argument<Int>("width")
        val height = call.argument<Int>("height")
        val rotationDegrees = call.argument<Int>("rotationDegrees") ?: 0
        val timestampMs = call.argument<Number>("timestampMs")?.toLong() ?: 0L

        if (bytes == null || width == null || height == null) {
            result.error("BAD_ARGS", "bytes/width/height em falta", null)
            return
        }

        val bitmap = nv21ToBitmap(bytes, width, height)
        val rotated = rotateBitmap(bitmap, rotationDegrees)
        lastImageWidth = rotated.width
        lastImageHeight = rotated.height

        val mpImage = BitmapImageBuilder(rotated).build()
        detector?.detectAsync(mpImage, timestampMs)
        result.success(null)
    }

    private fun nv21ToBitmap(nv21: ByteArray, width: Int, height: Int): Bitmap {
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 90, out)
        val jpegBytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Int): Bitmap {
        if (degrees == 0) return bitmap
        val matrix = Matrix().apply { postRotate(degrees.toFloat()) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    companion object {
        private const val MODEL_ASSET_PATH = "blaze_face_short_range.tflite"
        private const val MIN_DETECTION_CONFIDENCE = 0.5f
    }
}
