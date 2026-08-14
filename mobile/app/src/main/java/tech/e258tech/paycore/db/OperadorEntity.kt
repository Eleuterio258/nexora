package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "operadores")
data class OperadorEntity(
    @PrimaryKey val id: String,
    val nome: String,
    val pin: String,
    val perfil: String
)
