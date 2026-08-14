package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "categorias")
data class CategoriaEntity(
    @PrimaryKey val nome: String,
    val ordem: Int
)
