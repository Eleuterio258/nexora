package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Um dia de presença, tal como devolvido por GET /api/self-service/assiduidade/
 * no Nexora ERP (`MinhaAssiduidade`, backend/internal/modules/self-service/handlers/assiduidade.go).
 * Diferente do antigo modelo por evento (ENTRY/EXIT) do FaceClock: aqui é um
 * registo por dia, já com entrada e saída juntas.
 */
data class PresencaResponse(
    val id: Long,
    val data: String,
    val hora_entrada: String?,
    val hora_saida: String?,
    val horas_trabalhadas: Double?,
    val tipo: String,
    val latitude: Double?,
    val longitude: Double?,
    val observacao: String?
)
