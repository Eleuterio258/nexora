package tech.e258tech.nexora_assiduidade.utils

import android.graphics.Bitmap
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.toRequestBody

object ImageUtils {

    private const val JPEG_QUALITY = 85
    private val IMAGE_MEDIA_TYPE = "image/jpeg".toMediaTypeOrNull()

    /**
     * Comprime um Bitmap para JPEG e cria uma MultipartBody.Part pronta a
     * enviar num pedido Retrofit multipart/form-data.
     *
     * @param bitmap imagem capturada
     * @param formField nome do campo no form (ex: "image" ou "captures")
     * @param fileName nome do ficheiro sugerido
     */
    fun bitmapToMultipartPart(
        bitmap: Bitmap,
        formField: String,
        fileName: String = "capture.jpg"
    ): MultipartBody.Part {
        val stream = java.io.ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, stream)
        val bytes = stream.toByteArray()
        val requestBody = bytes.toRequestBody(IMAGE_MEDIA_TYPE, 0, bytes.size)
        return MultipartBody.Part.createFormData(formField, fileName, requestBody)
    }

    /**
     * Cria um RequestBody de texto plano para campos de form-data (ex: device_id).
     */
    fun textToRequestBody(text: String): okhttp3.RequestBody {
        return text.toRequestBody("text/plain".toMediaTypeOrNull())
    }
}
