package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface TransacaoDao {

    @Query("SELECT * FROM transacoes ORDER BY dataHora DESC")
    fun getAll(): List<TransacaoPDVEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(transacao: TransacaoPDVEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertAll(transacoes: List<TransacaoPDVEntity>)

    @Query("UPDATE transacoes SET estado = :estado WHERE id = :id")
    fun updateEstado(id: String, estado: String)

    @Query("UPDATE transacoes SET syncPendente = 0, syncStatus = 'SINCRONIZADO' WHERE id = :id")
    fun marcarSincronizado(id: String)

    @Query("UPDATE transacoes SET syncPendente = 0, syncStatus = 'SINCRONIZADO', serverId = :serverId WHERE id = :id")
    fun marcarSincronizado(id: String, serverId: Long)

    @Query("SELECT * FROM transacoes WHERE id = :id")
    fun getById(id: String): TransacaoPDVEntity?

    /** Exclui FALHADO — uma venda com falha permanente (ver SyncStatus) deixa de ser tentada
     * automaticamente em cada ronda, para não gastar rede/bateria numa causa que não se
     * resolve sozinha. Continua visível via [contarFalhadas]/[ultimoErroFalhado] para a UI. */
    @Query("SELECT * FROM transacoes WHERE syncPendente = 1 AND syncStatus != 'FALHADO' ORDER BY dataHora ASC")
    fun getPendentes(): List<TransacaoPDVEntity>

    /** Regista uma tentativa falhada (transitória ou permanente) — chamado nos pontos onde
     * antes havia um `continue` silencioso em PosStore.sincronizarTransacoesPendentes. */
    @Query("UPDATE transacoes SET syncStatus = :status, tentativas = tentativas + 1, ultimoErro = :erro, ultimaTentativaEm = :quando WHERE id = :id")
    fun registarTentativaFalhada(id: String, status: String, erro: String?, quando: Long)

    @Query("SELECT COUNT(*) FROM transacoes WHERE syncPendente = 1")
    fun contarPendentes(): Int

    @Query("SELECT COUNT(*) FROM transacoes WHERE syncStatus = 'FALHADO'")
    fun contarFalhadas(): Int

    @Query("SELECT ultimoErro FROM transacoes WHERE syncStatus = 'FALHADO' ORDER BY ultimaTentativaEm DESC LIMIT 1")
    fun ultimoErroFalhado(): String?

    /** Vendas aprovadas de uma sessão de caixa — usado para calcular o valor esperado no fecho local (offline). */
    @Query("SELECT * FROM transacoes WHERE sessaoLocalId = :sessaoLocalId AND estado = 'Aprovado'")
    fun getAprovadasPorSessao(sessaoLocalId: String): List<TransacaoPDVEntity>

    @Query("DELETE FROM transacoes")
    fun deleteAll()
}
