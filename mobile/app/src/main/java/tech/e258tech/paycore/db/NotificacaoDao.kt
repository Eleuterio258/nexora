package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface NotificacaoDao {

    @Query("SELECT * FROM notificacoes ORDER BY dataHora DESC")
    fun getAll(): List<NotificacaoEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(notificacao: NotificacaoEntity)

    @Query("UPDATE notificacoes SET lida = 1 WHERE id = :id")
    fun marcarLida(id: String)

    @Query("UPDATE notificacoes SET lida = 1")
    fun marcarTodasLidas()
}
