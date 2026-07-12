package tech.e258tech.nexora_assiduidade.ui.gestor.equipa

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Funcionario

class EquipaAdapter(
    private val items: List<Funcionario>,
    private val onClick: (Funcionario) -> Unit,
) : RecyclerView.Adapter<EquipaAdapter.FuncionarioViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FuncionarioViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_funcionario, parent, false)
        return FuncionarioViewHolder(view)
    }

    override fun onBindViewHolder(holder: FuncionarioViewHolder, position: Int) {
        holder.bind(items[position], onClick)
    }

    override fun getItemCount(): Int = items.size

    class FuncionarioViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvNome: TextView = itemView.findViewById(R.id.tvFuncionarioNome)
        private val tvCargo: TextView = itemView.findViewById(R.id.tvFuncionarioCargo)
        private val tvUnidade: TextView = itemView.findViewById(R.id.tvFuncionarioUnidade)
        private val tvEstado: TextView = itemView.findViewById(R.id.tvFuncionarioEstado)

        fun bind(item: Funcionario, onClick: (Funcionario) -> Unit) {
            tvNome.text = item.nome_completo
            tvCargo.text = item.cargo ?: "Sem cargo definido"
            tvUnidade.text = item.unidade_nome ?: "Sem unidade"
            tvEstado.text = when (item.estado) {
                "ativo" -> "Activo"
                "suspenso" -> "Suspenso"
                "licenca" -> "Em licença"
                "desligado" -> "Desligado"
                else -> item.estado
            }
            itemView.setOnClickListener { onClick(item) }
        }
    }
}
