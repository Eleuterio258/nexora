package tech.e258tech.nexora_assiduidade.ui.gestor.ocorrencias

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.PresencaOcorrencia
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

/** Partilhado por OcorrenciasFragment e AlertasFragment — mesma fonte de
 * dados (GET /api/rh/presencas), filtros diferentes. */
class OcorrenciasAdapter(
    private val items: List<PresencaOcorrencia>
) : RecyclerView.Adapter<OcorrenciasAdapter.OcorrenciaViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): OcorrenciaViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_ocorrencia, parent, false)
        return OcorrenciaViewHolder(view)
    }

    override fun onBindViewHolder(holder: OcorrenciaViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    class OcorrenciaViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvFuncionario: TextView = itemView.findViewById(R.id.tvOcorrenciaFuncionario)
        private val tvTipo: TextView = itemView.findViewById(R.id.tvOcorrenciaTipo)
        private val tvDetalhe: TextView = itemView.findViewById(R.id.tvOcorrenciaDetalhe)

        fun bind(item: PresencaOcorrencia) {
            tvFuncionario.text = item.funcionario_nome
            val (label, colorRes) = when (item.tipo) {
                "atraso" -> "Atraso" to R.color.amber
                "falta" -> "Falta" to R.color.red
                "saida_antecipada" -> "Saída antecipada" to R.color.amber
                else -> "Presente" to R.color.green
            }
            tvTipo.text = label
            tvTipo.setTextColor(itemView.context.getColor(colorRes))
            tvDetalhe.text = "${DateTimeUtils.formatDate(item.data)} — ${item.unidade_nome ?: "Sem unidade"}" +
                (item.hora_entrada?.let { " — entrada $it" } ?: "")
        }
    }
}
