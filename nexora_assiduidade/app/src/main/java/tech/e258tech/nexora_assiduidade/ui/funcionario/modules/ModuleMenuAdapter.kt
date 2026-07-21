package tech.e258tech.nexora_assiduidade.ui.funcionario.modules

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R

/** Um item do menu de Módulos — só é construído para módulos a que o utilizador tem acesso (ver [ModulesFragment]). */
data class ModuleMenuItem(
    val label: String,
    val iconRes: Int,
    val onClick: () -> Unit
)

class ModuleMenuAdapter(
    private val items: List<ModuleMenuItem>
) : RecyclerView.Adapter<ModuleMenuAdapter.ModuleViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ModuleViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_module_menu, parent, false)
        return ModuleViewHolder(view)
    }

    override fun onBindViewHolder(holder: ModuleViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    class ModuleViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val ivIcon: ImageView = itemView.findViewById(R.id.ivModuleIcon)
        private val tvLabel: TextView = itemView.findViewById(R.id.tvModuleLabel)

        fun bind(item: ModuleMenuItem) {
            ivIcon.setImageResource(item.iconRes)
            tvLabel.text = item.label
            itemView.setOnClickListener { item.onClick() }
        }
    }
}
