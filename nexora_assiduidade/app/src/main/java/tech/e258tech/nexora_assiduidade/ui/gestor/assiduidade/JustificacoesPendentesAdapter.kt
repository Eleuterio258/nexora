package tech.e258tech.nexora_assiduidade.ui.gestor.assiduidade

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.response.JustificacaoPendenteResponse
import tech.e258tech.nexora_assiduidade.utils.DateTimeUtils

class JustificacoesPendentesAdapter(
    private val items: MutableList<JustificacaoPendenteResponse>,
    private val onAprovar: (JustificacaoPendenteResponse) -> Unit,
    private val onRejeitar: (JustificacaoPendenteResponse) -> Unit,
) : RecyclerView.Adapter<JustificacoesPendentesAdapter.JustificacaoViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): JustificacaoViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_justificacao_pendente, parent, false)
        return JustificacaoViewHolder(view)
    }

    override fun onBindViewHolder(holder: JustificacaoViewHolder, position: Int) {
        holder.bind(items[position], onAprovar, onRejeitar)
    }

    override fun getItemCount(): Int = items.size

    fun removeItem(item: JustificacaoPendenteResponse) {
        val index = items.indexOf(item)
        if (index >= 0) {
            items.removeAt(index)
            notifyItemRemoved(index)
        }
    }

    class JustificacaoViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvFuncionario: TextView = itemView.findViewById(R.id.tvJustPendFuncionario)
        private val tvTipoData: TextView = itemView.findViewById(R.id.tvJustPendTipoData)
        private val tvMotivo: TextView = itemView.findViewById(R.id.tvJustPendMotivo)
        private val btnAprovar: Button = itemView.findViewById(R.id.btnJustPendAprovar)
        private val btnRejeitar: Button = itemView.findViewById(R.id.btnJustPendRejeitar)

        fun bind(
            item: JustificacaoPendenteResponse,
            onAprovar: (JustificacaoPendenteResponse) -> Unit,
            onRejeitar: (JustificacaoPendenteResponse) -> Unit
        ) {
            tvFuncionario.text = item.funcionario_nome
            val tipoLabel = if (item.tipo == "atraso") "Atraso" else "Falta"
            tvTipoData.text = "$tipoLabel · ${DateTimeUtils.formatDate(item.data)}"
            tvMotivo.text = item.motivo

            btnAprovar.setOnClickListener { onAprovar(item) }
            btnRejeitar.setOnClickListener { onRejeitar(item) }
        }
    }
}
