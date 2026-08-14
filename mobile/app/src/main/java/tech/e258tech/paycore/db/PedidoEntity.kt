package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "pedidos")
data class PedidoEntity(
    @PrimaryKey val id: String,
    val numero: Int,
    val nota: String,
    val itensJson: String,
    val total: Double,
    val dataHora: Long,
    val estado: String
)
