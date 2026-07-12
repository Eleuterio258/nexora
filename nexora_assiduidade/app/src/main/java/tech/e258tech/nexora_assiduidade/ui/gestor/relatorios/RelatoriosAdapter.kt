package tech.e258tech.nexora_assiduidade.ui.gestor.relatorios

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R

sealed class RelatorioRow {
    data class Header(val titulo: String) : RelatorioRow()
    data class Linha(val label: String, val valor: String) : RelatorioRow()
}

class RelatoriosAdapter(
    private val rows: List<RelatorioRow>
) : RecyclerView.Adapter<RelatoriosAdapter.RowViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RowViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_relatorio_linha, parent, false)
        return RowViewHolder(view)
    }

    override fun onBindViewHolder(holder: RowViewHolder, position: Int) {
        holder.bind(rows[position])
    }

    override fun getItemCount(): Int = rows.size

    class RowViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvLabel: TextView = itemView.findViewById(R.id.tvRelatorioLabel)
        private val tvValor: TextView = itemView.findViewById(R.id.tvRelatorioValor)

        fun bind(row: RelatorioRow) {
            when (row) {
                is RelatorioRow.Header -> {
                    tvLabel.text = row.titulo
                    tvLabel.setTextColor(itemView.context.getColor(R.color.brand_accent))
                    tvLabel.textSize = 16f
                    tvLabel.setTypeface(null, android.graphics.Typeface.BOLD)
                    tvValor.text = ""
                }
                is RelatorioRow.Linha -> {
                    tvLabel.text = row.label
                    tvLabel.setTextColor(itemView.context.getColor(R.color.text_muted))
                    tvLabel.textSize = 14f
                    tvLabel.setTypeface(null, android.graphics.Typeface.NORMAL)
                    tvValor.text = row.valor
                }
            }
        }
    }
}
