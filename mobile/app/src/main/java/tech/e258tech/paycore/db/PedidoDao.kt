package tech.e258tech.paycore.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface PedidoDao {

    @Query("SELECT * FROM pedidos WHERE estado != 'Cancelado' ORDER BY dataHora DESC")
    fun getAtivos(): List<PedidoEntity>

    @Query("SELECT COUNT(*) FROM pedidos")
    fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insert(pedido: PedidoEntity)

    @Query("UPDATE pedidos SET estado = :estado WHERE id = :id")
    fun updateEstado(id: String, estado: String)

    @Query("DELETE FROM pedidos WHERE id = :id")
    fun deleteById(id: String)

    @Query("DELETE FROM pedidos")
    fun deleteAll()
}
