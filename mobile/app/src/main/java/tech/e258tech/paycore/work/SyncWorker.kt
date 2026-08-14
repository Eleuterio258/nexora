package tech.e258tech.paycore.work

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import tech.e258tech.paycore.PosStore
import tech.e258tech.paycore.repository.SessionRepository
import java.util.concurrent.TimeUnit

/**
 * Sincroniza tudo o que ficou pendente offline (sessões de caixa, vendas,
 * estornos) — ver PosStore.sincronizarSessoesCaixaPendentes, que já orquestra
 * a ordem certa (o backend só permite uma sessão de caixa aberta por vez).
 *
 * Duas formas de disparo: periódico (rede de segurança, intervalo mínimo do
 * WorkManager) e pontual (logo que uma tentativa de rede tiver sucesso — ver
 * [enqueueOneTime], chamado a partir de PosStore.init).
 */
class SyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            PosStore.sincronizarSessoesCaixaPendentes()
            // Melhor esforço, nunca bloqueia nem falha o worker — só actualiza a cache de
            // permissões se já estiver desactualizada há mais do que o limiar por omissão
            // (ver SessionRepository.permissoesEstaoDesactualizadas). É o único mecanismo
            // já periódico + accionado em reconexão que existe no projecto.
            runCatching { SessionRepository.revalidarPermissoesSeNecessario() }
            Result.success()
        } catch (e: Exception) {
            // Nunca falha "a sério" — os dados continuam em Room como pendentes
            // e a próxima ronda (periódica ou pontual) tenta de novo.
            Result.retry()
        }
    }

    companion object {
        private const val PERIODIC_WORK_NAME = "paycore_sync_pendentes_periodico"

        private val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        /** Rede de segurança — corre ao intervalo mínimo permitido pelo WorkManager (15 min). */
        fun enqueuePeriodic(context: Context) {
            val request = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                PERIODIC_WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        /** Disparo pontual — chamado assim que se detecta rede disponível (ver PosStore.init),
         * para não esperar pelo próximo ciclo periódico. */
        fun enqueueOneTime(context: Context) {
            val request = OneTimeWorkRequestBuilder<SyncWorker>()
                .setConstraints(constraints)
                .build()
            WorkManager.getInstance(context).enqueue(request)
        }
    }
}
