package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface SessaoCaixaDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(sessao: SessaoCaixaEntity)

    @Query("SELECT * FROM sessoes_caixa WHERE localId = :localId")
    fun getById(localId: String): SessaoCaixaEntity?

    /** Sessão activa (aberta e ainda não fechada) — usada para restaurar estado ao arrancar a app. */
    @Query("SELECT * FROM sessoes_caixa WHERE status = 'ABERTA' ORDER BY abertaEm DESC LIMIT 1")
    fun getAberta(): SessaoCaixaEntity?

    /** Sessões cuja abertura ainda não chegou ao servidor, da mais antiga para a mais recente
     * — a ordem importa: o backend só permite uma sessão aberta por utilizador de cada vez.
     * Exclui FALHADO — uma sessão com falha permanente deixa de ser tentada automaticamente. */
    @Query("SELECT * FROM sessoes_caixa WHERE aberturaSincronizada = 0 AND syncStatus != 'FALHADO' ORDER BY abertaEm ASC")
    fun getPendentesAbertura(): List<SessaoCaixaEntity>

    /** Sessões já fechadas localmente mas cujo fecho ainda não foi confirmado pelo servidor. */
    @Query("SELECT * FROM sessoes_caixa WHERE status = 'FECHADA' AND fechoSincronizado = 0 AND syncStatus != 'FALHADO' ORDER BY abertaEm ASC")
    fun getPendentesFecho(): List<SessaoCaixaEntity>

    @Query("UPDATE sessoes_caixa SET serverId = :serverId, aberturaSincronizada = 1, syncStatus = 'PENDENTE', tentativas = 0 WHERE localId = :localId")
    fun marcarAberturaSincronizada(localId: String, serverId: Long)

    @Query("UPDATE sessoes_caixa SET status = 'FECHADA', closingAmount = :closingAmount, fechadaEm = :fechadaEm, diferencaLocal = :diferencaLocal, justificativaDiferenca = :justificativa, syncStatus = 'PENDENTE', tentativas = 0 WHERE localId = :localId")
    fun registarFechoLocal(localId: String, closingAmount: Double, fechadaEm: Long, diferencaLocal: Double, justificativa: String?)

    @Query("UPDATE sessoes_caixa SET fechoSincronizado = 1, diferencaLocal = :diferencaOficial, syncStatus = 'SINCRONIZADO' WHERE localId = :localId")
    fun marcarFechoSincronizado(localId: String, diferencaOficial: Double)

    /** Regista uma tentativa falhada (transitória ou permanente, ver SyncStatus) — chamado nos
     * pontos onde antes havia um `continue`/`break` silencioso em PosStore.sincronizarSessoesCaixaPendentes. */
    @Query("UPDATE sessoes_caixa SET syncStatus = :status, tentativas = tentativas + 1, ultimoErro = :erro, ultimaTentativaEm = :quando WHERE localId = :localId")
    fun registarTentativaFalhada(localId: String, status: String, erro: String?, quando: Long)

    @Query("SELECT COUNT(*) FROM sessoes_caixa WHERE syncStatus = 'FALHADO'")
    fun contarFalhados(): Int

    @Query("SELECT ultimoErro FROM sessoes_caixa WHERE syncStatus = 'FALHADO' ORDER BY ultimaTentativaEm DESC LIMIT 1")
    fun ultimoErroFalhado(): String?

    @Query("DELETE FROM sessoes_caixa")
    fun deleteAll()
}
