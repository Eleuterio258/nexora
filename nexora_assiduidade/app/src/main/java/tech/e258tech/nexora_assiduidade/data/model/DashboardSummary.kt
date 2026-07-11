package tech.e258tech.nexora_assiduidade.data.model

data class DashboardSummary(
    val totalFuncionarios: Int,
    val presentesHoje: Int,
    val ausentesHoje: Int,
    val atrasosHoje: Int,
    val reunioesDoDia: Int,
    val alertasPendentes: Int
)
