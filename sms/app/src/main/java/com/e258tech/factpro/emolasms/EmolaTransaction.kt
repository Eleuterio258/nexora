package com.e258tech.factpro.emolasms

/**
 * Representa qualquer SMS recebido da e-mola. Apenas "chave", "tipo",
 * "remetente", "corpoOriginal" e "recebidoEm" sao garantidos; os restantes
 * campos dependem do tipo de mensagem e podem nao existir.
 */
data class EmolaTransaction(
    val chave: String,
    val tipo: String,
    val transacaoId: String?,
    val valor: String?,
    val conta: String?,
    val nome: String?,
    val hora: String?,
    val data: String?,
    val taxa: String?,
    val saldo: String?,
    val conteudo: String?,
    val remetente: String,
    val corpoOriginal: String,
    val recebidoEm: Long
)
