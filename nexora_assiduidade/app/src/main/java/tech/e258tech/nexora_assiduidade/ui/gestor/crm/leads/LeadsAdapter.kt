package tech.e258tech.nexora_assiduidade.ui.gestor.crm.leads

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Lead

class LeadsAdapter(
    private val items: List<Lead>,
    private val onClick: (Lead) -> Unit,
) : RecyclerView.Adapter<LeadsAdapter.LeadViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): LeadViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_lead, parent, false)
        return LeadViewHolder(view)
    }

    override fun onBindViewHolder(holder: LeadViewHolder, position: Int) {
        holder.bind(items[position], onClick)
    }

    override fun getItemCount(): Int = items.size

    class LeadViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvNome: TextView = itemView.findViewById(R.id.tvLeadNome)
        private val tvEmpresa: TextView = itemView.findViewById(R.id.tvLeadEmpresa)
        private val tvEstado: TextView = itemView.findViewById(R.id.tvLeadEstado)
        private val tvOrigem: TextView = itemView.findViewById(R.id.tvLeadOrigem)

        fun bind(item: Lead, onClick: (Lead) -> Unit) {
            tvNome.text = item.nome
            tvEmpresa.text = item.empresa ?: "Sem empresa associada"
            tvEstado.text = "Estado: ${Lead.estadoLabel(item.estado)}"
            tvOrigem.text = "Origem: ${Lead.origemLabel(item.origem)}"
            itemView.setOnClickListener { onClick(item) }
        }
    }
}
