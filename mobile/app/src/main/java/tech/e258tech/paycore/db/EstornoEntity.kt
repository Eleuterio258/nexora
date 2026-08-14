package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Pedido de estorno enfileirado — antes disto existir, estornarTransacao()
 * era fire-and-forget (PosStore.estornarTransacaoSelecionada) e perdia-se
 * silenciosamente sem rede. Mesmo padrão de TransacaoPDVEntity.syncPendente,
 * num registo próprio porque um estorno não tem "corpo" além da referência
 * à transacção e do motivo.
 */
@Entity(tableName = "estornos_pendentes")
data class EstornoEntity(
    @PrimaryKey val transacaoId: String,
    val motivo: String,
    val criadoEm: Long,
    val sincronizado: Boolean = false,
    // Máquina de estados de sincronização (ver SyncStatus) — aditivo a sincronizado.
    val syncStatus: String = SyncStatus.PENDENTE,
    val tentativas: Int = 0,
    val ultimoErro: String? = null,
    val ultimaTentativaEm: Long? = null
)
