package tech.e258tech.nexora_assiduidade.data.model

data class Device(
    val id: String,
    val name: String,
    val type: String, // "nfc", "qr_code", "biometria"
    val location: String,
    val status: String, // "online", "offline", "manutencao"
    val lastActivity: String
)
