package com.e258tech.factpro.emolasms

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class TransactionAdapter(
    private var itens: MutableList<EmolaTransaction>
) : RecyclerView.Adapter<TransactionAdapter.ViewHolder>() {

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val titulo: TextView = view.findViewById(R.id.textoTitulo)
        val detalhe: TextView = view.findViewById(R.id.textoDetalhe)
    }

    fun atualizar(novos: List<EmolaTransaction>) {
        itens = novos.toMutableList()
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_transaction, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val t = itens[position]
        val tipoCapitalizado = t.tipo.replaceFirstChar { it.uppercase() }
        val valorTexto = t.valor?.let { "$it MT" } ?: "-"
        holder.titulo.text = "$tipoCapitalizado: ${t.nome ?: t.remetente} - $valorTexto"

        val dataHora = listOfNotNull(t.data, t.hora).joinToString(" ")
        holder.detalhe.text = "ID: ${t.transacaoId ?: "-"} | Conta: ${t.conta ?: "-"} | $dataHora"
    }

    override fun getItemCount(): Int = itens.size
}
