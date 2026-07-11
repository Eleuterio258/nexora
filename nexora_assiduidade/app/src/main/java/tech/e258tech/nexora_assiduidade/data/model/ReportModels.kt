package tech.e258tech.nexora_assiduidade.data.model

// Relatórios
data class AttendanceReport(
    val employeeId: String,
    val employeeName: String,
    val department: String,
    val totalDias: Int,
    val presencas: Int,
    val ausencias: Int,
    val atrasos: Int,
    val percentualPresenca: Float
)

data class AttendanceReportResponse(
    val success: Boolean,
    val message: String,
    val data: List<AttendanceReport>
)
