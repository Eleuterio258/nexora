package tech.e258tech.nexora_assiduidade.data.model.response

import tech.e258tech.nexora_assiduidade.data.model.Employee

data class EmployeeListResponse(
    val success: Boolean,
    val message: String,
    val data: List<Employee>
)
