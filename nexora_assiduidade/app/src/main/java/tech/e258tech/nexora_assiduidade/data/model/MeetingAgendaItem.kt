package tech.e258tech.nexora_assiduidade.data.model

data class MeetingAgendaItem(
    val id: String,
    val meetingId: String,
    val title: String,
    val description: String,
    val duration: Int, // minutos
    val presenter: String
)
