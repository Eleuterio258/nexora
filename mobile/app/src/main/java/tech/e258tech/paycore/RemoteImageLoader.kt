package tech.e258tech.paycore

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.widget.ImageView
import androidx.collection.LruCache
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

object RemoteImageLoader {
    private val cache = LruCache<String, Bitmap>(20)
    private val executor = Executors.newFixedThreadPool(4)
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Tenta ficheiro local primeiro; se não existir, descarrega do URL remoto. */
    fun load(imageView: ImageView, localPath: String?, remoteUrl: String?) {
        val key = localPath?.takeIf { File(it).exists() } ?: remoteUrl ?: return
        imageView.tag = key
        imageView.setImageDrawable(null)

        cache.get(key)?.let { imageView.setImageBitmap(it); return }

        executor.execute {
            val bitmap = when {
                !localPath.isNullOrBlank() && File(localPath).exists() -> decodeFile(localPath)
                !remoteUrl.isNullOrBlank()                             -> downloadUrl(remoteUrl)
                else -> null
            } ?: return@execute

            cache.put(key, bitmap)
            mainHandler.post {
                if (imageView.tag == key) imageView.setImageBitmap(bitmap)
            }
        }
    }

    /** Sobrecarga para compatibilidade com chamadas existentes (só URL). */
    fun load(imageView: ImageView, url: String) = load(imageView, null, url)

    private fun decodeFile(path: String): Bitmap? =
        runCatching { BitmapFactory.decodeFile(path) }.getOrNull()

    private fun downloadUrl(url: String): Bitmap? {
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 10_000
            readTimeout    = 10_000
            instanceFollowRedirects = true
            doInput = true
        }
        return try {
            connection.connect()
            if (connection.responseCode in 200..299) {
                connection.inputStream.use { BitmapFactory.decodeStream(it) }
            } else null
        } catch (_: Exception) {
            null
        } finally {
            connection.disconnect()
        }
    }
}
