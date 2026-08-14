package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "transacoes")
data class TransacaoPDVEntity(
    @PrimaryKey val id: String,
    val referencia: String,
    val metodo: String,
    val operadorId: String,
    val operadorNome: String,
    val dataHora: Long,
    val itensJson: String,
    val subtotal: Double,
    val desconto: Double,
    val total: Double,
    val estado: String,
    val syncPendente: Boolean = true,
    // Referencia SessaoCaixaEntity.localId — a sessão de caixa da venda,
    // resolvida para o id do servidor só no momento de sincronizar (ver
    // SyncWorker). "" para linhas anteriores a esta coluna (MIGRATION_7_8) —
    // ficam sem sessão local associada, mas continuam sincronizáveis pelo
    // caminho antigo se já tiverem sessaoAtualId gravado por fora.
    val sessaoLocalId: String = "",
    // id de pos_sales no servidor — só preenchido depois de sincronizada
    // (ver PosStore.processarPagamento/sincronizarTransacoesPendentes).
    // Necessário para o estorno parcial (POST pos/sales/{id}/estorno-parcial),
    // que referencia a venda pelo id do servidor, não pela referência local.
    val serverId: Long? = null,
    // Máquina de estados de sincronização (ver SyncStatus) — aditivo a syncPendente,
    // que continua a ser a fonte de verdade de "já terminou ou não".
    val syncStatus: String = SyncStatus.PENDENTE,
    val tentativas: Int = 0,
    val ultimoErro: String? = null,
    val ultimaTentativaEm: Long? = null
)
