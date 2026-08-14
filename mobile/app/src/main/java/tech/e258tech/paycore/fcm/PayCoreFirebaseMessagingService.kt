package tech.e258tech.paycore.fcm

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import tech.e258tech.paycore.R
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.PushTokenRequest
import tech.e258tech.paycore.db.AppDatabase
import tech.e258tech.paycore.db.NotificacaoEntity
import java.util.UUID

/**
 * Serviço Firebase Cloud Messaging do PayCore.
 *
 * Recebe novos tokens FCM e notificações push. O token é registado no backend
 * via [POST /api/auth/push-token] para que o servidor possa enviar pushes
 * direccionados a este dispositivo (incluindo broadcast para o tenant).
 */
class PayCoreFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "Novo token FCM: $token")
        registarTokenNoBackend(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        val titulo = message.notification?.title ?: message.data["title"] ?: return
        val corpo = message.notification?.body ?: message.data["body"].orEmpty()
        Log.d(TAG, "Push recebido: $titulo - $corpo")

        val notificacao = NotificacaoEntity(
            id = UUID.randomUUID().toString(),
            titulo = titulo,
            mensagem = corpo,
            dataHora = System.currentTimeMillis()
        )
        CoroutineScope(Dispatchers.IO).launch {
            AppDatabase.getInstance(applicationContext).notificacaoDao().insert(notificacao)
        }
        mostrarNotificacaoLocal(titulo, corpo)
    }

    /** Notificação Android real (heads-up/tray) além da persistência acima — ver
     * NotificacoesActivity para o histórico. Requer POST_NOTIFICATIONS concedida pelo
     * utilizador em Android 13+; se não concedida, a notificação fica só no histórico. */
    private fun mostrarNotificacaoLocal(titulo: String, corpo: String) {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = NotificationChannel(CANAL_ID, "Notificações PayCore", NotificationManager.IMPORTANCE_DEFAULT)
            manager.createNotificationChannel(canal)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val notification = NotificationCompat.Builder(this, CANAL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(titulo)
            .setContentText(corpo)
            .setAutoCancel(true)
            .build()
        NotificationManagerCompat.from(this).notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun registarTokenNoBackend(token: String) {
        if (!ApiClient.isLoggedIn && !ApiClient.isTerminalConfigured) {
            // Só envia o token se houver uma sessão (funcionário ou terminal)
            // configurada. Se a app ainda não foi activada, guarda localmente
            // para registo posterior.
            Log.w(TAG, "Token FCM ignorado — ainda não há sessão configurada")
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val response = ApiClient.service.registerPushToken(
                    PushTokenRequest(token = token, platform = "android")
                )
                if (response.isSuccessful) {
                    Log.i(TAG, "Token FCM registado no backend com sucesso")
                } else {
                    Log.w(TAG, "Falha ao registar token FCM: ${response.code()}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Excepção ao registar token FCM", e)
            }
        }
    }

    companion object {
        private const val TAG = "PayCoreFCM"
        private const val CANAL_ID = "paycore_notificacoes"
    }
}
