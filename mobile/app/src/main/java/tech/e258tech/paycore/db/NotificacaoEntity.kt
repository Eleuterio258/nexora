package tech.e258tech.paycore.db

import androidx.room.Entity
import androidx.room.PrimaryKey

/** Notificação recebida via push FCM e persistida localmente — ver
 * PayCoreFirebaseMessagingService.onMessageReceived, que grava aqui em vez de
 * só logar. NotificacoesActivity lê desta tabela em vez de uma lista fixa. */
@Entity(tableName = "notificacoes")
data class NotificacaoEntity(
    @PrimaryKey val id: String,
    val titulo: String,
    val mensagem: String,
    val dataHora: Long,
    val lida: Boolean = false
)
