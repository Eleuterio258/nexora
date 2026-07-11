package tech.e258tech.nexora_assiduidade.work

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit
import tech.e258tech.nexora_assiduidade.data.local.AppDatabase
import tech.e258tech.nexora_assiduidade.data.local.PendingEventEntity
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Worker responsavel por sincronizar eventos de presenca pendentes
 * com o backend quando a rede estiver disponivel.
 */
class SyncAttendanceWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private val dao = AppDatabase.getInstance(context).pendingEventDao()
    private val sessionManager = SessionManager(context)

    override suspend fun doWork(): Result {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            return Result.retry()
        }

        val pendingEvents = dao.getByStatus(PendingEventEntity.SyncStatus.PENDING)
        if (pendingEvents.isEmpty()) {
            return Result.success()
        }

        var allSuccessful = true
        val bearerToken = ApiUtils.bearerToken(token)

        pendingEvents.forEach { event ->
            val updated = event.copy(syncStatus = PendingEventEntity.SyncStatus.SYNCING)
            dao.update(updated)

            try {
                val response = RetrofitClient.assiduidadeApiService.registerClock(
                    bearerToken,
                    ClockRegisterRequest(
                        idempotency_key = event.idempotencyKey,
                        user_id = event.userId,
                        device_id = event.deviceId,
                        event_type = event.eventType,
                        recorded_at = event.recordedAt,
                        source = event.source,
                        confidence_score = event.confidenceScore,
                        liveness_score = event.livenessScore,
                        geo_lat = event.geoLat,
                        geo_lng = event.geoLng,
                        image_base64 = event.imageBase64
                    )
                )

                if (response.isSuccessful && response.body() != null) {
                    dao.delete(event)
                } else {
                    allSuccessful = false
                    dao.update(
                        event.copy(
                            syncStatus = PendingEventEntity.SyncStatus.FAILED,
                            errorMessage = ApiUtils.errorMessage(response)
                        )
                    )
                }
            } catch (e: Exception) {
                allSuccessful = false
                dao.update(
                    event.copy(
                        syncStatus = PendingEventEntity.SyncStatus.FAILED,
                        errorMessage = e.message ?: "Erro desconhecido"
                    )
                )
            }
        }

        return if (allSuccessful) Result.success() else Result.retry()
    }

    companion object {
        private const val SYNC_WORK_NAME = "sync_attendance_work"
        private const val PERIODIC_SYNC_WORK_NAME = "periodic_sync_attendance_work"

        /**
         * Agenda uma sincronizacao imediata (one-time) quando a rede estiver disponivel.
         */
        fun scheduleImmediate(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = OneTimeWorkRequestBuilder<SyncAttendanceWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 10, TimeUnit.MINUTES)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                SYNC_WORK_NAME,
                ExistingWorkPolicy.REPLACE,
                request
            )
        }

        /**
         * Agenda sincronizacao periodica para garantir que eventos pendentes
         * antigos sejam enviados mesmo que o utilizador nao abra a app.
         */
        fun schedulePeriodic(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = PeriodicWorkRequestBuilder<SyncAttendanceWorker>(15, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                PERIODIC_SYNC_WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(SYNC_WORK_NAME)
            WorkManager.getInstance(context).cancelUniqueWork(PERIODIC_SYNC_WORK_NAME)
        }
    }
}
