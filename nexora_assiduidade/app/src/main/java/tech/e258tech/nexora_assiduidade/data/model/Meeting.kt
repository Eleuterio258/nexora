package tech.e258tech.nexora_assiduidade.data.model

data class Meeting(
    val id: String,
    val title: String,
    val description: String,
    val date: String,
    val time: String,
    val location: String,
    val organizerId: String,
    val organizerName: String,
    val participants: List<String>,
    val status: String // "agendada", "em_curso", "concluida", "cancelada"
)
