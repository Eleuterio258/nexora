package tech.e258tech.nexora_assiduidade.data.model

data class Notification(
    val id: String,
    val title: String,
    val message: String,
    val type: String, // "info", "warning", "error", "success"
    val timestamp: String,
    val isRead: Boolean,
    val actionUrl: String? = null
)
