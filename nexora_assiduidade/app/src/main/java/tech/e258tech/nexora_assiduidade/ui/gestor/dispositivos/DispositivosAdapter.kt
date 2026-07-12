package tech.e258tech.nexora_assiduidade.ui.gestor.dispositivos

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.DispositivoErp

class DispositivosAdapter(
    private val items: List<DispositivoErp>
) : RecyclerView.Adapter<DispositivosAdapter.DeviceViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DeviceViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_dispositivo, parent, false)
        return DeviceViewHolder(view)
    }

    override fun onBindViewHolder(holder: DeviceViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    class DeviceViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvNome: TextView = itemView.findViewById(R.id.tvDeviceNome)
        private val tvTipo: TextView = itemView.findViewById(R.id.tvDeviceTipo)
        private val tvLocalizacao: TextView = itemView.findViewById(R.id.tvDeviceLocalizacao)
        private val tvEstado: TextView = itemView.findViewById(R.id.tvDeviceEstado)

        fun bind(item: DispositivoErp) {
            tvNome.text = item.nome
            tvTipo.text = "${item.tipo} — ${item.modelo}"
            tvLocalizacao.text = item.localizacao ?: "Sem localização definida"
            tvEstado.text = if (item.ativo) "Activo" else "Inactivo"
        }
    }
}
