package tech.e258tech.paycore

import android.app.Application
import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.utils.TerminalTokenManager
import tech.e258tech.paycore.work.SyncWorker

class PayCoreApp : Application() {

    override fun onCreate() {
        super.onCreate()
        ApiClient.init(this)
        PosStore.init(this)
        // Rede de segurança para sessões/vendas/estornos pendentes — ver SyncWorker.
        // O disparo pontual (mais rápido, ao detectar rede) já acontece dentro de
        // PosStore.init(); isto é só o intervalo periódico mínimo (15 min).
        SyncWorker.enqueuePeriodic(this)

        // Renova o token do terminal automaticamente se estiver perto de expirar.
        // Não bloqueia o arranque da app — corre em background.
        if (TerminalTokenManager.isTerminalLogged(this)) {
            CoroutineScope(Dispatchers.IO).launch {
                TerminalTokenManager.refreshIfNeeded(this@PayCoreApp)
            }
        }

        // Solicita o token FCM actual. Se o token mudar, o PayCoreFirebaseMessagingService
        // chama onNewToken e regista-o no backend; se for o mesmo, continua válido.
        FirebaseMessaging.getInstance().token
            .addOnCompleteListener { task ->
                if (!task.isSuccessful) {
                    Log.w("PayCore_FCM", "Falha ao obter token FCM", task.exception)
                    return@addOnCompleteListener
                }
                Log.i("PayCore_FCM", "Token FCM obtido: ${task.result}")
            }

        // Captura crashes não tratados e regista no logcat
        val handler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            Log.e("PayCore_CRASH", "Crash na thread ${thread.name}", throwable)
            handler?.uncaughtException(thread, throwable)
        }

        Log.i("PayCore", "App iniciada — versão ${packageManager.getPackageInfo(packageName, 0).versionName}")
    }

    companion object {
        const val TAG = "PayCore"
    }
}

