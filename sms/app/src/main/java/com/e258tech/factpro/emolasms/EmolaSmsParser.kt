package com.e258tech.factpro.emolasms

import java.util.regex.Pattern

/**
 * Extrai o maximo de informacao possivel de QUALQUER SMS enviado pela e-mola
 * (transferencia, recebimento, levantamento, pagamento, compra de saldo, etc.).
 * Cada campo e opcional e procurado de forma independente no corpo da mensagem,
 * para nao depender de um unico formato rigido. O corpo original e sempre
 * guardado, para nao se perder nenhuma mensagem mesmo que nenhum campo
 * especifico seja reconhecido.
 */
object EmolaSmsParser {

    private val PADRAO_ID = Pattern.compile("^([A-Za-z0-9]+(?:\\.[A-Za-z0-9]+)+)\\.\\s")

    private val VERBOS = "Transferiste|Recebeste|Levantaste|Pagaste|Depositaste|Compraste|Comprou|Carregaste|Enviaste"

    private val PADRAO_TIPO = Pattern.compile("\\b($VERBOS)\\b", Pattern.CASE_INSENSITIVE)
    private val PADRAO_VALOR = Pattern.compile(
        "(?:$VERBOS)\\s+([\\d.,]+)\\s*MT",
        Pattern.CASE_INSENSITIVE
    )
    private val PADRAO_CONTA = Pattern.compile("conta\\s+(\\d{6,})", Pattern.CASE_INSENSITIVE)
    private val PADRAO_NOME = Pattern.compile(
        "nome:\\s*(.+?)(?:\\s+as\\s+\\d{2}:\\d{2}:\\d{2}|[,.]|$)",
        Pattern.CASE_INSENSITIVE
    )
    private val PADRAO_HORA = Pattern.compile("(\\d{2}:\\d{2}:\\d{2})")
    private val PADRAO_DATA = Pattern.compile("(\\d{2}/\\d{2}/\\d{4})")
    private val PADRAO_TAXA = Pattern.compile("Taxa:\\s*([\\d.,]+)\\s*MT", Pattern.CASE_INSENSITIVE)
    private val PADRAO_SALDO = Pattern.compile("saldo[^\\d]*?([\\d.,]+)\\s*MT", Pattern.CASE_INSENSITIVE)
    private val PADRAO_CONTEUDO = Pattern.compile("Conteudo:\\s*(\\d+)", Pattern.CASE_INSENSITIVE)

    fun ehEmola(remetente: String): Boolean =
        remetente.contains("mola", ignoreCase = true)

    fun parse(remetente: String, corpo: String, recebidoEm: Long): EmolaTransaction {
        val texto = corpo.trim()

        val id = grupo(PADRAO_ID, texto)
        val tipo = grupo(PADRAO_TIPO, texto)?.lowercase() ?: "outro"
        val valor = grupo(PADRAO_VALOR, texto)
        val conta = grupo(PADRAO_CONTA, texto)
        val nome = grupo(PADRAO_NOME, texto)
        val hora = grupo(PADRAO_HORA, texto)
        val data = grupo(PADRAO_DATA, texto)
        val taxa = grupo(PADRAO_TAXA, texto)
        val saldo = grupo(PADRAO_SALDO, texto)
        val conteudo = grupo(PADRAO_CONTEUDO, texto)

        // Sem ID de transacao (mensagens sem esse padrao), usa uma chave
        // derivada para ainda assim evitar duplicados no ficheiro JSON.
        val chave = id ?: "$remetente|$recebidoEm|${texto.hashCode()}"

        return EmolaTransaction(
            chave = chave,
            tipo = tipo,
            transacaoId = id,
            valor = valor,
            conta = conta,
            nome = nome,
            hora = hora,
            data = data,
            taxa = taxa,
            saldo = saldo,
            conteudo = conteudo,
            remetente = remetente,
            corpoOriginal = corpo,
            recebidoEm = recebidoEm
        )
    }

    private fun grupo(padrao: Pattern, texto: String): String? {
        val matcher = padrao.matcher(texto)
        return if (matcher.find()) matcher.group(1)?.trim() else null
    }
}
