package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View
import tech.e258tech.nexora_assiduidade.utils.FaceDetectorHelper

/**
 * Desenha, por cima do preview da camara (CameraX PreviewView), a caixa
 * delimitadora devolvida pelo MediaPipe FaceDetector — verde quando o
 * enquadramento esta bom o suficiente para auto-capturar, amarelo caso
 * contrario. Puramente visual: quem decide o enquadramento e o Fragment.
 */
class FaceOverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : View(context, attrs) {

    private var faceResult: FaceDetectorHelper.FaceResult? = null
    private var isWellFramed: Boolean = false

    private val boxPaintGood = Paint().apply {
        color = Color.parseColor("#22C55E")
        style = Paint.Style.STROKE
        strokeWidth = 6f
    }
    private val boxPaintBad = Paint().apply {
        color = Color.parseColor("#FBBF24")
        style = Paint.Style.STROKE
        strokeWidth = 6f
    }

    fun update(result: FaceDetectorHelper.FaceResult?, wellFramed: Boolean) {
        faceResult = result
        isWellFramed = wellFramed
        invalidate()
    }

    fun clear() {
        faceResult = null
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val result = faceResult ?: return
        if (result.imageWidth == 0 || result.imageHeight == 0) return

        // A pre-visualizacao usa scaleType "fillCenter": a imagem da camara e
        // ampliada para cobrir a view mantendo o aspect ratio, cortando o
        // excesso. Escolhemos o maior factor de escala (cobrir) e centramos.
        val scaleX = width.toFloat() / result.imageWidth
        val scaleY = height.toFloat() / result.imageHeight
        val scale = maxOf(scaleX, scaleY)
        val offsetX = (width - result.imageWidth * scale) / 2f
        val offsetY = (height - result.imageHeight * scale) / 2f

        val box = result.boundingBox
        val mapped = RectF(
            box.left * scale + offsetX,
            box.top * scale + offsetY,
            box.right * scale + offsetX,
            box.bottom * scale + offsetY,
        )
        canvas.drawRoundRect(mapped, 24f, 24f, if (isWellFramed) boxPaintGood else boxPaintBad)
    }
}
