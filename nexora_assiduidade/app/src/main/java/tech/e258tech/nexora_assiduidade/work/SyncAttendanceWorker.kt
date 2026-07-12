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
import tech.e258tech.nexora_assiduidade.data.model.ClockBatchRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.OfflineEventCrypto
import tech.e258tech.nexora_assiduidade.utils.SessionManager

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

        val pendingEvents = dao.getByStatuses(
            listOf(PendingEventEntity.SyncStatus.PENDING, PendingEventEntity.SyncStatus.FAILED),
            100
        )
        if (pendingEvents.isEmpty()) {
            return Result.success()
        }

        pendingEvents.forEach { event ->
            dao.update(event.copy(syncStatus = PendingEventEntity.SyncStatus.SYNCING))
        }

        val eventsByIdempotencyKey = mutableMapOf<String, PendingEventEntity>()
        val requests = pendingEvents.mapNotNull { event ->
            val request = event.toClockRegisterRequest()
            if (request == null) {
                dao.update(
                    event.copy(
                        syncStatus = PendingEventEntity.SyncStatus.FAILED,
                        errorMessage = "Falha ao decifrar evento offline."
                    )
                )
            } else {
                eventsByIdempotencyKey[request.idempotency_key] = event
            }
            request
        }

        if (requests.isEmpty()) {
            return Result.failure()
        }

        return try {
            val response = RetrofitClient.assiduidadeApiService.registerClockBatch(
                ApiUtils.bearerToken(token),
                ClockBatchRegisterRequest(requests)
            )

            if (!response.isSuccessful || response.body() == null) {
                markBatchFailed(pendingEvents, ApiUtils.errorMessage(response))
                return Result.retry()
            }

            val body = response.body()!!
            body.accepted.forEach { accepted ->
                eventsByIdempotencyKey[accepted.idempotency_key]?.let { dao.delete(it) }
            }

            body.rejected.forEach { rejected ->
                eventsByIdempotencyKey[rejected.idempotency_key]?.let { event ->
                    if (rejected.status_code == 409) {
                        dao.delete(event)
                    } else {
                        dao.update(
                            event.copy(
                                syncStatus = PendingEventEntity.SyncStatus.FAILED,
                                errorMessage = rejected.detail ?: "Evento rejeitado pelo backend."
                            )
                        )
                    }
                }
            }

            if (body.rejected.isEmpty()) Result.success() else Result.retry()
        } catch (e: Exception) {
            markBatchFailed(pendingEvents, e.message ?: "Erro desconhecido")
            Result.retry()
        }
    }

    private suspend fun markBatchFailed(events: List<PendingEventEntity>, message: String) {
        events.forEach { event ->
            dao.update(
                event.copy(
                    syncStatus = PendingEventEntity.SyncStatus.FAILED,
                    errorMessage = message
                )
            )
        }
    }

    private fun PendingEventEntity.toClockRegisterRequest(): ClockRegisterRequest? {
        val idempotency = OfflineEventCrypto.decrypt(idempotencyKey) ?: return null
        val user = OfflineEventCrypto.decrypt(userId) ?: return null
        val device = OfflineEventCrypto.decrypt(deviceId) ?: return null
        val type = OfflineEventCrypto.decrypt(eventType) ?: return null
        val recorded = OfflineEventCrypto.decrypt(recordedAt) ?: return null
        val eventSource = OfflineEventCrypto.decrypt(source) ?: return null

        return ClockRegisterRequest(
            idempotency_key = idempotency,
            user_id = user,
            device_id = device,
            event_type = type,
            recorded_at = recorded,
            source = eventSource,
            confidence_score = confidenceScore,
            liveness_score = livenessScore,
            geo_lat = geoLat,
            geo_lng = geoLng,
            image_base64 = OfflineEventCrypto.decrypt(imageBase64)
        )
    }

    companion object {
        private const val SYNC_WORK_NAME = "sync_attendance_work"
        private const val PERIODIC_SYNC_WORK_NAME = "periodic_sync_attendance_work"

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
