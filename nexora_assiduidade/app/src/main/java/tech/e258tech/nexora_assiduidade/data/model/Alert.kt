package tech.e258tech.nexora_assiduidade.data.model

data class Alert(
    val id: String,
    val type: String, // "atraso", "ausencia", "dispositivo", "anomalia"
    val title: String,
    val description: String,
    val timestamp: String,
    val isRead: Boolean,
    val severity: String // "baixa", "media", "alta", "critica"
)
