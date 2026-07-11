package tech.e258tech.nexora_assiduidade.data.network

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query
import tech.e258tech.nexora_assiduidade.data.model.AttendanceReportResponse
import tech.e258tech.nexora_assiduidade.data.model.ChatMessageRequest
import tech.e258tech.nexora_assiduidade.data.model.MeetingCreateRequest
import tech.e258tech.nexora_assiduidade.data.model.response.AgendaListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.AlertListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ChatMessageListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.ChatMessageResponse
import tech.e258tech.nexora_assiduidade.data.model.response.DashboardSummaryResponse
import tech.e258tech.nexora_assiduidade.data.model.response.DepartamentoListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.DeviceListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.EmployeeDetailResponse
import tech.e258tech.nexora_assiduidade.data.model.response.EmployeeListResponse
import tech.e258tech.nexora_assiduidade.data.model.response.MeetingCreateResponse
import tech.e258tech.nexora_assiduidade.data.model.response.MeetingDetailResponse
import tech.e258tech.nexora_assiduidade.data.model.response.NotificationListResponse

/**
 * Serviços da API do ERP
 */
interface ErpApiService {
    
    // Lista de funcionários
    @GET("employees")
    suspend fun getEmployees(
        @Header("Authorization") token: String,
        @Query("departamento") departamento: String? = null,
        @Query("status") status: String? = null
    ): Response<EmployeeListResponse>
    
    // Detalhe do funcionário
    @GET("employees/{id}")
    suspend fun getEmployeeDetail(
        @Header("Authorization") token: String,
        @Path("id") employeeId: String
    ): Response<EmployeeDetailResponse>
    
    // Departamentos
    @GET("departments")
    suspend fun getDepartments(
        @Header("Authorization") token: String
    ): Response<DepartamentoListResponse>
    
    // Dashboard dados para gestor
    @GET("dashboard/summary")
    suspend fun getDashboardSummary(
        @Header("Authorization") token: String
    ): Response<DashboardSummaryResponse>
    
    // Alertas e ocorrências
    @GET("alerts")
    suspend fun getAlerts(
        @Header("Authorization") token: String,
        @Query("type") type: String? = null
    ): Response<AlertListResponse>
    
    // Dispositivos
    @GET("devices")
    suspend fun getDevices(
        @Header("Authorization") token: String
    ): Response<DeviceListResponse>
    
    // Relatórios
    @GET("reports/attendance")
    suspend fun getAttendanceReport(
        @Header("Authorization") token: String,
        @Query("startDate") startDate: String,
        @Query("endDate") endDate: String,
        @Query("department") department: String? = null
    ): Response<AttendanceReportResponse>
    
    // Agenda/Reuniões
    @GET("agenda")
    suspend fun getAgenda(
        @Header("Authorization") token: String,
        @Query("startDate") startDate: String? = null,
        @Query("endDate") endDate: String? = null
    ): Response<AgendaListResponse>
    
    @POST("agenda/meetings")
    suspend fun createMeeting(
        @Header("Authorization") token: String,
        @Body request: MeetingCreateRequest
    ): Response<MeetingCreateResponse>
    
    @GET("agenda/meetings/{id}")
    suspend fun getMeetingDetail(
        @Header("Authorization") token: String,
        @Path("id") meetingId: String
    ): Response<MeetingDetailResponse>
    
    // Notificações
    @GET("notifications")
    suspend fun getNotifications(
        @Header("Authorization") token: String,
        @Query("unread") unread: Boolean? = null
    ): Response<NotificationListResponse>
    
    // Chat
    @GET("chat/messages")
    suspend fun getChatMessages(
        @Header("Authorization") token: String,
        @Query("chatId") chatId: String
    ): Response<ChatMessageListResponse>
    
    @POST("chat/send")
    suspend fun sendChatMessage(
        @Header("Authorization") token: String,
        @Body request: ChatMessageRequest
    ): Response<ChatMessageResponse>
}
