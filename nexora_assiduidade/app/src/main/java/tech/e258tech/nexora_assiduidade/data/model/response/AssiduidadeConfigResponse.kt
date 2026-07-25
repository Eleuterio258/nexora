package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * GET /api/system/configuracao/tenant/feature/rh.assiduidade no Nexora ERP
 * (`ObterConfigAssiduidade`, backend/internal/modules/sistema-configuracao/handlers/assiduidade.go).
 *
 * `configuracao.metodos` usa as mesmas chaves de
 * `_SOURCE_TO_METODO` em assiduidade_system_backend/app/services/attendance_validation.py:
 * facial, fingerprint, qr_code, nfc, selfie, geolocation, pin, manual. Um
 * método sem entrada no mapa é tratado como activo por omissão (fail-open,
 * ver validar_metodo_assiduidade).
 */
data class AssiduidadeConfigResponse(
    val activo: Boolean,
    val configuracao: ConfiguracaoAssiduidade?
)

data class ConfiguracaoAssiduidade(
    val metodos: Map<String, MetodoAssiduidadeConfig>? = null
)

data class MetodoAssiduidadeConfig(
    val ativo: Boolean = true
)
