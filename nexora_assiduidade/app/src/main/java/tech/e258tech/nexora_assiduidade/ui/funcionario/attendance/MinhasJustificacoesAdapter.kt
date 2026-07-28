package tech.e258tech.nexora_assiduidade.ui.funcionario.attendance

import android.content.res.ColorStateList
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.response.JustificacaoResponse
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

/**
 * Histórico de justificações do próprio colaborador — GET
 * /api/self-service/assiduidade/justificacoes. Antes desta lista existir no
 * ecrã, o colaborador submetia uma justificação e não tinha nenhuma forma de
 * ver se tinha sido aprovada/rejeitada.
 */
class MinhasJustificacoesAdapter(
    private val items: List<JustificacaoResponse>
) : RecyclerView.Adapter<MinhasJustificacoesAdapter.JustificacaoViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): JustificacaoViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_minha_justificacao, parent, false)
        return JustificacaoViewHolder(view)
    }

    override fun onBindViewHolder(holder: JustificacaoViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    class JustificacaoViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvTipoData: TextView = itemView.findViewById(R.id.tvJustificacaoTipoData)
        private val tvEstado: TextView = itemView.findViewById(R.id.tvJustificacaoEstado)
        private val tvMotivo: TextView = itemView.findViewById(R.id.tvJustificacaoMotivo)

        fun bind(item: JustificacaoResponse) {
            val tipoLabel = if (item.tipo == "atraso") "Atraso" else "Falta"
            tvTipoData.text = "$tipoLabel · ${DateTimeUtils.formatDate(item.data)}"
            tvMotivo.text = item.motivo

            val context = itemView.context
            val (label, colorRes) = when (item.estado) {
                "aprovado" -> "Aprovado" to R.color.green
                "rejeitado" -> "Rejeitado" to R.color.red
                else -> "Pendente" to R.color.amber
            }
            val cor = context.getColor(colorRes)
            tvEstado.text = label
            tvEstado.setTextColor(cor)
            tvEstado.compoundDrawableTintList = ColorStateList.valueOf(cor)
        }
    }
}
