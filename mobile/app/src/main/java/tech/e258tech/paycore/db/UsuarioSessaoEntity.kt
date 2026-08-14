package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "usuario_sessao")
data class UsuarioSessaoEntity(
    @PrimaryKey val uid: String,
    val nome: String,
    val email: String,
    val role: String,
    val tenantId: String,
    // JSON com {"pos":["operar_pos","gerir_catalogo"],...}
    val modulosJson: String,
    val updatedAt: Long
)
