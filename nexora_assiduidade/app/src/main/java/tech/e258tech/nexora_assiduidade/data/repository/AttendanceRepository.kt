package tech.e258tech.nexora_assiduidade.data.repository

import android.content.Context
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import tech.e258tech.nexora_assiduidade.BuildConfig
import tech.e258tech.nexora_assiduidade.data.local.AppDatabase
import tech.e258tech.nexora_assiduidade.data.local.PendingEventEntity
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.response.HardwareEventResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.HardwareEventMapper
import tech.e258tech.nexora_assiduidade.utils.OfflineEventCrypto
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import tech.e258tech.nexora_assiduidade.work.SyncAttendanceWorker

/**
 * Repositorio responsavel pelo registo de presenca.
 *
 * Desde 2026-07-13 chama directamente `POST /api/hardware/events/generic` no
 * Nexora ERP (API Key de device embutida no APK, `BuildConfig.DEVICE_API_KEY`)
 * — deixou de passar pelo proxy do FaceClock. Ver o aviso de risco em
 * app/build.gradle.kts.
 *
 * Tenta enviar o evento para o ERP imediatamente. Se nao houver conectividade
 * ou o servidor nao responder, o evento e guardado localmente (Room) e sincronizado
 * mais tarde via WorkManager.
 */
class AttendanceRepository(context: Context) {

    private val appContext = context.applicationContext
    private val erpApiService = RetrofitClient.erpApiService
    private val sessionManager = SessionManager(appContext)
    private val pendingEventDao = AppDatabase.getInstance(appContext).pendingEventDao()

    sealed class RegisterResult {
        data class Success(val response: HardwareEventResponse) : RegisterResult()
        data class SavedOffline(val pendingId: Long) : RegisterResult()
        data class Error(val message: String) : RegisterResult()
    }

    suspend fun registerClock(request: ClockRegisterRequest): RegisterResult {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            return RegisterResult.Error("Sessao invalida. Faca login novamente.")
        }

        val employeeCode = HardwareEventMapper.resolveEmployeeCode(sessionManager)
            ?: return RegisterResult.Error("Nao foi possivel identificar o funcionario no ERP.")

        return try {
            val eventRequest = HardwareEventMapper.toGenericHardwareEvent(request, employeeCode)
            val response = erpApiService.registerEventDevice(BuildConfig.DEVICE_API_KEY, eventRequest)

            if (response.isSuccessful && response.body() != null) {
                RegisterResult.Success(response.body()!!)
            } else {
                val errorMessage = errorMessageDevice(response.code(), response.errorBody()?.string())
                if (shouldSaveOffline(response.code())) {
                    saveOffline(request, errorMessage)
                } else {
                    RegisterResult.Error(errorMessage)
                }
            }
        } catch (e: Exception) {
            when (e) {
                is IOException,
                is SocketTimeoutException,
                is UnknownHostException -> saveOffline(request, e.message)
                else -> RegisterResult.Error(e.message ?: "Erro desconhecido")
            }
        }
    }

    private fun errorMessageDevice(code: Int, body: String?): String {
        return body?.takeIf { it.isNotBlank() } ?: "Erro ao registar ponto (HTTP $code)."
    }

    /**
     * Guarda o evento na fila local para sincronizacao futura.
     */
    private suspend fun saveOffline(
        request: ClockRegisterRequest,
        errorMessage: String?
    ): RegisterResult {
        val entity = PendingEventEntity(
            userId = OfflineEventCrypto.encrypt(request.user_id) ?: request.user_id,
            deviceId = OfflineEventCrypto.encrypt(request.device_id) ?: request.device_id,
            eventType = OfflineEventCrypto.encrypt(request.event_type) ?: request.event_type,
            recordedAt = OfflineEventCrypto.encrypt(request.recorded_at) ?: request.recorded_at,
            source = OfflineEventCrypto.encrypt(request.source) ?: request.source,
            confidenceScore = request.confidence_score,
            livenessScore = request.liveness_score,
            geoLat = request.geo_lat,
            geoLng = request.geo_lng,
            imageBase64 = OfflineEventCrypto.encrypt(request.image_base64),
            idempotencyKey = OfflineEventCrypto.encrypt(request.idempotency_key) ?: request.idempotency_key,
            syncStatus = PendingEventEntity.SyncStatus.PENDING,
            errorMessage = errorMessage
        )
        val id = pendingEventDao.insert(entity)
        SyncAttendanceWorker.scheduleImmediate(appContext)
        return RegisterResult.SavedOffline(id)
    }

    /**
     * Determina se um erro HTTP deve resultar em guardar offline.
     * Apenas erros de cliente 4xx (exceto 408/429) e 5xx nao sao guardados offline.
     */
    private fun shouldSaveOffline(code: Int): Boolean {
        return code == 408 || code == 429 || code >= 500
    }
}
