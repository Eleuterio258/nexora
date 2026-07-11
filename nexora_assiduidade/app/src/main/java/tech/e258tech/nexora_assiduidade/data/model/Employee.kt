package tech.e258tech.nexora_assiduidade.data.model

data class Employee(
    val id: String,
    val name: String,
    val email: String,
    val departamento: String,
    val cargo: String,
    val telefone: String? = null,
    val fotoUrl: String? = null,
    val status: String = "ativo", // "ativo", "inativo", "ferias"
    val dataAdmissao: String? = null
)
