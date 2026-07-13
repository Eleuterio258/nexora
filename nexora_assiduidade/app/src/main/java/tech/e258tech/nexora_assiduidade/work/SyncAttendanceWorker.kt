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
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.data.local.AppDatabase
import tech.e258tech.nexora_assiduidade.data.local.PendingEventEntity
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.HardwareEventMapper
import tech.e258tech.nexora_assiduidade.utils.OfflineEventCrypto
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Reenvia eventos de ponto guardados offline.
 *
 * Desde 2026-07-13 chama `POST /api/hardware/events/generic` directamente no
 * Nexora ERP, um por um (API Key de device) — deixou de usar o
 * `clock/register/batch` do FaceClock (removido). O ERP não expõe hoje um
 * lote autenticado por device com o mesmo contrato simples, por isso o
 * "lote" é agora um ciclo de chamadas individuais em vez de um único pedido
 * HTTP; o volume é baixo (só acumula depois de períodos offline) por isso
 * não é um problema de desempenho real.
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

        val employeeCode = HardwareEventMapper.resolveEmployeeCode(sessionManager)
        if (employeeCode == null) {
            markBatchFailed(pendingEvents, "Nao foi possivel identificar o funcionario no ERP.")
            return Result.retry()
        }

        var anyFailed = false
        for (event in pendingEvents) {
            val request = event.toClockRegisterRequest()
            if (request == null) {
                dao.update(
                    event.copy(
                        syncStatus = PendingEventEntity.SyncStatus.FAILED,
                        errorMessage = "Falha ao decifrar evento offline."
                    )
                )
                anyFailed = true
                continue
            }

            try {
                val eventRequest = HardwareEventMapper.toGenericHardwareEvent(request, employeeCode)
                val response = RetrofitClient.erpApiService.registerEventDevice(
                    BuildConfig.DEVICE_API_KEY,
                    eventRequest
                )
                if (response.isSuccessful && response.body()?.processed == true) {
                    dao.delete(event)
                } else {
                    dao.update(
                        event.copy(
                            syncStatus = PendingEventEntity.SyncStatus.FAILED,
                            errorMessage = response.body()?.error
                                ?: response.errorBody()?.string()
                                ?: "Evento rejeitado pelo ERP (HTTP ${response.code()})."
                        )
                    )
                    anyFailed = true
                }
            } catch (e: Exception) {
                dao.update(
                    event.copy(
                        syncStatus = PendingEventEntity.SyncStatus.FAILED,
                        errorMessage = e.message ?: "Erro desconhecido"
                    )
                )
                anyFailed = true
            }
        }

        return if (anyFailed) Result.retry() else Result.success()
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
