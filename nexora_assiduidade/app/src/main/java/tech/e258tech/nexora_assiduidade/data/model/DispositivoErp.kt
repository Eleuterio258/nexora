package tech.e258tech.nexora_assiduidade.data.model

/**
 * GET /api/hardware/devices (ERP, Go) — ver
 * backend/internal/modules/hardware/handlers/devices.go:29 (`DeviceResponse`).
 * Cadastro real dos leitores biométricos (ZKTeco/Hikvision/etc.) do tenant —
 * não confundir com `Device`/`admin/devices` do FaceClock (cadastro interno
 * simples, entretanto removido do FaceClock).
 */
data class DispositivoErp(
    val id: Long,
    val tenant_id: Long,
    val branch_id: Long?,
    val nome: String,
    val serial_number: String?,
    val modelo: String,
    val localizacao: String?,
    val tipo: String,
    val driver: String,
    val ip_permitido: String?,
    val api_key_prefix: String,
    val ativo: Boolean,
    val ultimo_uso_em: String?,
    val created_at: String
)
