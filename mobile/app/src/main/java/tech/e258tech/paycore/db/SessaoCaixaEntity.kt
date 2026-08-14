package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Sessão de caixa (abertura/fecho de turno), gravada localmente antes de
 * existir uma sessão correspondente no servidor — permite abrir/fechar caixa
 * offline. [localId] é a identidade estável usada pela UI e por
 * TransacaoPDVEntity.sessaoLocalId; [serverId] só fica preenchido depois de
 * sincronizada (ver SyncWorker, que reconcilia via GET pos/sessoes/atual).
 */
@Entity(tableName = "sessoes_caixa")
data class SessaoCaixaEntity(
    @PrimaryKey val localId: String,
    val serverId: Long? = null,
    val terminalId: Long,
    val openingAmount: Double,
    val abertaEm: Long,
    val closingAmount: Double? = null,
    val fechadaEm: Long? = null,
    // Diferença calculada no cliente ao fechar offline (openingAmount + soma
    // das vendas locais da sessão − closingAmount) — é uma estimativa; o
    // valor oficial vem de FecharSessaoResponse.diferenca quando sincronizar.
    val diferencaLocal: Double? = null,
    val status: String, // "ABERTA" | "FECHADA"
    val aberturaSincronizada: Boolean = false,
    val fechoSincronizado: Boolean = false,
    // Justificativa da diferença de caixa, escrita pelo operador ao fechar —
    // o backend passou a exigi-la quando há diferença não-trivial (ver
    // FecharSessao em pos.go), por isso tem de viajar com o fecho pendente
    // até à sincronização, não só no pedido imediato.
    val justificativaDiferenca: String? = null,
    // Máquina de estados de sincronização (ver SyncStatus) — cobre qualquer que seja o passo
    // pendente de momento (abertura ou fecho, nunca os dois ao mesmo tempo, já que o fecho só
    // é tentado depois da abertura sincronizar). Reinicia para PENDENTE quando um passo
    // conclui com sucesso e o seguinte ainda não foi tentado.
    val syncStatus: String = SyncStatus.PENDENTE,
    val tentativas: Int = 0,
    val ultimoErro: String? = null,
    val ultimaTentativaEm: Long? = null
)
