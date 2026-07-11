package tech.e258tech.nexora_assiduidade.data.model

data class MeetingCreateRequest(
    val title: String,
    val description: String,
    val date: String,
    val time: String,
    val location: String,
    val participants: List<String>,
    val agendaItems: List<MeetingAgendaItem>? = null
)
