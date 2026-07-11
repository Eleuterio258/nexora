package tech.e258tech.nexora_assiduidade.data.model

// Férias / Pedidos
data class VacationRequest(
    val id: String,
    val employeeId: String,
    val employeeName: String,
    val startDate: String,
    val endDate: String,
    val status: String, // "pendente", "aprovado", "rejeitado"
    val motivo: String,
    val dataCriacao: String
)

data class VacationRequestListResponse(
    val success: Boolean,
    val message: String,
    val data: List<VacationRequest>
)

data class VacationRequestCreate(
    val employeeId: String,
    val startDate: String,
    val endDate: String,
    val motivo: String
)

data class VacationRequestResponse(
    val success: Boolean,
    val message: String,
    val data: VacationRequest?
)

data class VacationRequestDetailResponse(
    val success: Boolean,
    val message: String,
    val data: VacationRequest
)
