package tech.e258tech.nexora_assiduidade.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Entidade Room para eventos de presenca pendentes de sincronizacao.
 * E utilizada quando o dispositivo esta offline no momento do registo.
 */
@Entity(tableName = "pending_events")
data class PendingEventEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val userId: String,
    val deviceId: String,
    val eventType: String,
    val recordedAt: String,
    val source: String,
    val confidenceScore: Double? = null,
    val livenessScore: Double? = null,
    val geoLat: Double? = null,
    val geoLng: Double? = null,
    val imageBase64: String? = null,
    // PIN cifrado (OfflineEventCrypto) das marcacoes por PIN feitas offline:
    // o ERP so aceita o evento depois de verificar o PIN na sincronizacao
    // (POST /api/self-service/assiduidade/ponto/batch). Apagado com o evento.
    val pin: String? = null,
    val idempotencyKey: String,
    val syncStatus: String = SyncStatus.PENDING,
    val createdAt: Long = System.currentTimeMillis(),
    val errorMessage: String? = null
) {
    object SyncStatus {
        const val PENDING = "PENDING"
        const val SYNCING = "SYNCING"
        const val FAILED = "FAILED"
        // Rejeitado pelo ERP de forma definitiva (PIN errado, mais de 72h,
        // metodo desactivado...). Nao volta a ser enviado.
        const val REJECTED = "REJECTED"
    }
}
