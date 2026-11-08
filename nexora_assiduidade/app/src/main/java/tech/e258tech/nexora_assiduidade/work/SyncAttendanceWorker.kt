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
import tech.e258tech.nexora_assiduidade.data.model.MarcacaoOfflineRequest
import tech.e258tech.nexora_assiduidade.data.model.MarcarPontoLoteRequest
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.OfflineEventCrypto
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Reenvia as marcacoes guardadas offline num unico pedido a
 * `POST /api/self-service/assiduidade/ponto/batch`, com o JWT do colaborador.
 * Ate 2026-09-26 enviava uma a uma para `POST /api/hardware/events/generic`
 * com a API Key de device.
 *
 * O ERP responde por marcacao: "registado" e "duplicado" (idempotency_key ja
 * sincronizada num envio anterior) apagam o evento local; "rejeitado" e
 * definitivo e fica marcado como REJECTED com o motivo, sem voltar a ser
 * enviado. So as falhas de rede ou do servidor voltam a tentar.
 */
class SyncAttendanceWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private val dao = AppDatabase.getInstance(context).pendingEventDao()
    private val sessionManager = SessionManager(context)

    override suspend fun doWork(): Result {
        val token = sessionManager.getToken()
        val sessionUserId = sessionManager.getUserId()
        if (token.isNullOrBlank() || sessionUserId.isNullOrBlank()) {
            return Result.retry()
        }

        // SYNCING tambem entra: se o worker foi morto a meio de um envio, o
        // evento ficava preso nesse estado. Reenviar e seguro porque o ERP
        // deduplica pela idempotency_key.
        val pendingEvents = dao.getByStatuses(
            listOf(
                PendingEventEntity.SyncStatus.PENDING,
                PendingEventEntity.SyncStatus.FAILED,
                PendingEventEntity.SyncStatus.SYNCING
            ),
            100
        )
        if (pendingEvents.isEmpty()) {
            return Result.success()
        }

        // Cada marcacao so pode ser enviada com a sessao de quem a fez: o ERP
        // grava o ponto no utilizador do JWT. As de outro utilizador que usou
        // este telemovel ficam na fila ate essa pessoa voltar a entrar.
        val porChave = LinkedHashMap<String, PendingEventEntity>()
        val itens = mutableListOf<MarcacaoOfflineRequest>()
        for (event in pendingEvents) {
            val request = event.toMarcacaoOffline()
            if (request == null) {
                dao.update(
                    event.copy(
                        syncStatus = PendingEventEntity.SyncStatus.REJECTED,
                        errorMessage = "Falha ao decifrar evento offline."
                    )
                )
                continue
            }
            if (OfflineEventCrypto.decrypt(event.userId) != sessionUserId) {
                continue
            }
            porChave[request.idempotency_key] = event
            itens += request
        }
        if (itens.isEmpty()) {
            return Result.success()
        }

        porChave.values.forEach { dao.update(it.copy(syncStatus = PendingEventEntity.SyncStatus.SYNCING)) }

        val response = try {
            RetrofitClient.erpApiService.marcarPontoLote(
                ApiUtils.bearerToken(token),
                MarcarPontoLoteRequest(eventos = itens)
            )
        } catch (e: Exception) {
            markFailed(porChave.values, e.message ?: "Erro desconhecido")
            return Result.retry()
        }

        val body = response.body()
        if (!response.isSuccessful || body == null) {
            markFailed(porChave.values, ApiUtils.errorMessage(response))
            return Result.retry()
        }

        var anyPending = false
        val respondidos = mutableSetOf<String>()
        for (resultado in body.resultados) {
            val event = porChave[resultado.idempotency_key] ?: continue
            respondidos += resultado.idempotency_key
            if (resultado.sincronizado) {
                dao.delete(event)
            } else {
                dao.update(
                    event.copy(
                        syncStatus = PendingEventEntity.SyncStatus.REJECTED,
                        // O PIN deixa de ser util: nao o manter guardado.
                        pin = null,
                        errorMessage = resultado.erro ?: "Marcacao rejeitada pelo ERP."
                    )
                )
            }
        }
        val semResposta = porChave.filterKeys { it !in respondidos }.values
        if (semResposta.isNotEmpty()) {
            markFailed(semResposta, "Sem resposta do ERP para esta marcacao.")
            anyPending = true
        }

        return if (anyPending) Result.retry() else Result.success()
    }

    private suspend fun markFailed(events: Collection<PendingEventEntity>, message: String) {
        events.forEach { event ->
            dao.update(
                event.copy(
                    syncStatus = PendingEventEntity.SyncStatus.FAILED,
                    errorMessage = message
                )
            )
        }
    }

    private fun PendingEventEntity.toMarcacaoOffline(): MarcacaoOfflineRequest? {
        val idempotency = OfflineEventCrypto.decrypt(idempotencyKey) ?: return null
        val device = OfflineEventCrypto.decrypt(deviceId) ?: return null
        val recorded = OfflineEventCrypto.decrypt(recordedAt) ?: return null
        val metodo = metodoDaFonte(OfflineEventCrypto.decrypt(source) ?: return null)
        val tipo = tipoEventoCodigo(OfflineEventCrypto.decrypt(eventType).orEmpty())

        return MarcacaoOfflineRequest(
            idempotency_key = idempotency,
            metodo = metodo,
            ocorrido_em = recorded,
            device_id = device,
            pin = OfflineEventCrypto.decrypt(pin),
            tipo_evento_codigo = tipo,
            latitude = geoLat,
            longitude = geoLng
        )
    }

    companion object {
        private const val SYNC_WORK_NAME = "sync_attendance_work"
        private const val PERIODIC_SYNC_WORK_NAME = "periodic_sync_attendance_work"

        /**
         * Eventos guardados por versoes anteriores da app tinham `source` no
         * formato do contrato de hardware (PIN, FINGERPRINT, ...). O ERP recusa
         * os que nao sao PIN/impressao digital com uma mensagem clara.
         */
        internal fun metodoDaFonte(source: String): String = when (source.uppercase()) {
            "PIN" -> "pin"
            "FINGERPRINT" -> "fingerprint"
            "FACIAL" -> "facial"
            "QR_CODE" -> "qr_code"
            "NFC" -> "nfc"
            "SELFIE_GPS", "GEOLOCATION" -> "selfie_gps"
            else -> source.lowercase()
        }

        /** Converte os tipos antigos (ENTRY/EXIT/AUTO) para os codigos do ERP. */
        internal fun tipoEventoCodigo(eventType: String): String? = when (eventType.uppercase()) {
            "", "AUTO" -> null
            "ENTRY" -> "entrada"
            "EXIT" -> "saida"
            "BREAK_START" -> "intervalo_inicio"
            "BREAK_END" -> "intervalo_fim"
            else -> eventType
        }

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
