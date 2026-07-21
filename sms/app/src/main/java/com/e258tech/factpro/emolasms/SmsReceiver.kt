package com.e258tech.factpro.emolasms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.widget.Toast

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        // SMS longos (como as mensagens da e-mola, tipicamente > 160 caracteres)
        // chegam como varias partes concatenadas no mesmo intent. E preciso
        // juntar todas as partes antes de analisar, senao cada parte e tratada
        // como uma mensagem incompleta e a transacao fica corrompida/perdida.
        val partes = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (partes.isEmpty()) return

        val remetente = partes[0].originatingAddress ?: return
        if (!EmolaSmsParser.ehEmola(remetente)) return

        val corpo = partes.joinToString(separator = "") { it.messageBody ?: "" }
        val recebidoEm = partes[0].timestampMillis

        val transacao = EmolaSmsParser.parse(remetente, corpo, recebidoEm)
        val nova = TransactionStore.adicionar(context, transacao)
        if (nova) {
            Toast.makeText(
                context,
                "Mensagem e-mola guardada (${transacao.tipo})",
                Toast.LENGTH_LONG
            ).show()
        }
    }
}
