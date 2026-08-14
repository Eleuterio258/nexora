package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface EstornoDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(estorno: EstornoEntity)

    @Query("SELECT * FROM estornos_pendentes WHERE sincronizado = 0 AND syncStatus != 'FALHADO' ORDER BY criadoEm ASC")
    fun getPendentes(): List<EstornoEntity>

    @Query("UPDATE estornos_pendentes SET sincronizado = 1, syncStatus = 'SINCRONIZADO' WHERE transacaoId = :transacaoId")
    fun marcarSincronizado(transacaoId: String)

    /** Regista uma tentativa falhada (transitória ou permanente) — chamado nos pontos onde
     * antes havia um `continue` silencioso em PosStore.sincronizarEstornosPendentes. */
    @Query("UPDATE estornos_pendentes SET syncStatus = :status, tentativas = tentativas + 1, ultimoErro = :erro, ultimaTentativaEm = :quando WHERE transacaoId = :transacaoId")
    fun registarTentativaFalhada(transacaoId: String, status: String, erro: String?, quando: Long)

    @Query("SELECT COUNT(*) FROM estornos_pendentes WHERE sincronizado = 0")
    fun contarPendentes(): Int

    @Query("SELECT COUNT(*) FROM estornos_pendentes WHERE syncStatus = 'FALHADO'")
    fun contarFalhados(): Int

    @Query("SELECT ultimoErro FROM estornos_pendentes WHERE syncStatus = 'FALHADO' ORDER BY ultimaTentativaEm DESC LIMIT 1")
    fun ultimoErroFalhado(): String?

    @Query("DELETE FROM estornos_pendentes")
    fun deleteAll()
}
