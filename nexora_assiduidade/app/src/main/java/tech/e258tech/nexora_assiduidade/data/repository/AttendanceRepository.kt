package tech.e258tech.nexora_assiduidade.data.repository

import android.content.Context
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import tech.e258tech.nexora_assiduidade.data.local.AppDatabase
import tech.e258tech.nexora_assiduidade.data.local.PendingEventEntity
import tech.e258tech.nexora_assiduidade.data.model.ClockRegisterRequest
import tech.e258tech.nexora_assiduidade.data.model.response.ClockRecordResponse
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager
import tech.e258tech.nexora_assiduidade.work.SyncAttendanceWorker

/**
 * Repositorio responsavel pelo registo de presenca.
 *
 * Tenta enviar o evento para o backend imediatamente. Se nao houver conectividade
 * ou o servidor nao responder, o evento e guardado localmente (Room) e sincronizado
 * mais tarde via WorkManager.
 */
class AttendanceRepository(context: Context) {

    private val appContext = context.applicationContext
    private val apiService = RetrofitClient.assiduidadeApiService
    private val sessionManager = SessionManager(appContext)
    private val pendingEventDao = AppDatabase.getInstance(appContext).pendingEventDao()

    sealed class RegisterResult {
        data class Success(val response: ClockRecordResponse) : RegisterResult()
        data class SavedOffline(val pendingId: Long) : RegisterResult()
        data class Error(val message: String) : RegisterResult()
    }

    suspend fun registerClock(request: ClockRegisterRequest): RegisterResult {
        val token = sessionManager.getToken()
        if (token.isNullOrBlank()) {
            return RegisterResult.Error("Sessao invalida. Faca login novamente.")
        }

        return try {
            val response = apiService.registerClock(
                ApiUtils.bearerToken(token),
                request
            )

            if (response.isSuccessful && response.body() != null) {
                RegisterResult.Success(response.body()!!)
            } else {
                val errorMessage = ApiUtils.errorMessage(response)
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

    /**
     * Guarda o evento na fila local para sincronizacao futura.
     */
    private suspend fun saveOffline(
        request: ClockRegisterRequest,
        errorMessage: String?
    ): RegisterResult {
        val entity = PendingEventEntity(
            userId = request.user_id,
            deviceId = request.device_id,
            eventType = request.event_type,
            recordedAt = request.recorded_at,
            source = request.source,
            confidenceScore = request.confidence_score,
            livenessScore = request.liveness_score,
            geoLat = request.geo_lat,
            geoLng = request.geo_lng,
            imageBase64 = request.image_base64,
            idempotencyKey = request.idempotency_key,
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
