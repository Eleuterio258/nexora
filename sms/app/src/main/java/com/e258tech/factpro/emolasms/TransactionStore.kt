package com.e258tech.factpro.emolasms

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Guarda todas as mensagens da e-mola extraidas num ficheiro JSON em
 * armazenamento especifico da app (getExternalFilesDir), sem necessitar de
 * permissoes extra de armazenamento.
 */
object TransactionStore {

    private const val NOME_FICHEIRO = "emola_transactions.json"

    private fun ficheiro(context: Context): File =
        File(context.getExternalFilesDir(null), NOME_FICHEIRO)

    fun carregar(context: Context): MutableList<EmolaTransaction> {
        val ficheiro = ficheiro(context)
        if (!ficheiro.exists()) return mutableListOf()

        val texto = ficheiro.readText()
        if (texto.isBlank()) return mutableListOf()

        val array = JSONArray(texto)
        val lista = mutableListOf<EmolaTransaction>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            lista.add(
                EmolaTransaction(
                    chave = obj.getString("chave"),
                    tipo = obj.getString("tipo"),
                    transacaoId = campoOpcional(obj, "transacaoId"),
                    valor = campoOpcional(obj, "valor"),
                    conta = campoOpcional(obj, "conta"),
                    nome = campoOpcional(obj, "nome"),
                    hora = campoOpcional(obj, "hora"),
                    data = campoOpcional(obj, "data"),
                    taxa = campoOpcional(obj, "taxa"),
                    saldo = campoOpcional(obj, "saldo"),
                    conteudo = campoOpcional(obj, "conteudo"),
                    remetente = obj.getString("remetente"),
                    corpoOriginal = obj.getString("corpoOriginal"),
                    recebidoEm = obj.getLong("recebidoEm")
                )
            )
        }
        return lista
    }

    private fun campoOpcional(obj: JSONObject, chave: String): String? =
        if (!obj.has(chave) || obj.isNull(chave)) null else obj.getString(chave)

    private fun guardar(context: Context, transacoes: List<EmolaTransaction>) {
        val array = JSONArray()
        for (t in transacoes) {
            val obj = JSONObject()
            obj.put("chave", t.chave)
            obj.put("tipo", t.tipo)
            obj.put("transacaoId", t.transacaoId ?: JSONObject.NULL)
            obj.put("valor", t.valor ?: JSONObject.NULL)
            obj.put("conta", t.conta ?: JSONObject.NULL)
            obj.put("nome", t.nome ?: JSONObject.NULL)
            obj.put("hora", t.hora ?: JSONObject.NULL)
            obj.put("data", t.data ?: JSONObject.NULL)
            obj.put("taxa", t.taxa ?: JSONObject.NULL)
            obj.put("saldo", t.saldo ?: JSONObject.NULL)
            obj.put("conteudo", t.conteudo ?: JSONObject.NULL)
            obj.put("remetente", t.remetente)
            obj.put("corpoOriginal", t.corpoOriginal)
            obj.put("recebidoEm", t.recebidoEm)
            array.put(obj)
        }
        ficheiro(context).writeText(array.toString(2))
    }

    /** Adiciona a mensagem se a chave ainda nao existir. Devolve true se foi nova. */
    fun adicionar(context: Context, transacao: EmolaTransaction): Boolean {
        val lista = carregar(context)
        if (lista.any { it.chave == transacao.chave }) {
            return false
        }
        lista.add(0, transacao)
        guardar(context, lista)
        return true
    }

    fun caminhoFicheiro(context: Context): String = ficheiro(context).absolutePath
}
