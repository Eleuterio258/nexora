package tech.e258tech.nexora_assiduidade.data.model

/**
 * GET /api/rh/ausencias (ERP, Go) — ver
 * backend/internal/modules/recursos-humanos/handlers/rh.go:1090
 * (`ListarAusencias`). Devolve array simples (sem paginação/envelope).
 *
 * Tabela genérica de ausências (férias/licenças/doença/etc., distinguidas por
 * `tipo_nome`) — não confundir com `AdjustmentRequest` do FaceClock, que é um
 * pedido de correcção de um registo de ponto, conceito diferente.
 */
data class Ausencia(
    val id: Long,
    val funcionario_id: Long,
    val funcionario_nome: String?,
    val tipo_id: Long?,
    val tipo_nome: String?,
    val data_inicio: String,
    val data_fim: String,
    val dias: Int?,
    val motivo: String?,
    val estado: String, // "pendente", "aprovado", "rejeitado"
    val aprovado_em: String?
)
