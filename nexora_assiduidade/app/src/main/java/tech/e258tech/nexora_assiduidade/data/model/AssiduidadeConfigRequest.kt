package tech.e258tech.nexora_assiduidade.data.model

import tech.e258tech.nexora_assiduidade.data.model.response.ConfiguracaoAssiduidade

/**
 * PUT /api/system/configuracao/tenant/feature/rh.assiduidade no Nexora ERP
 * (`GuardarConfigAssiduidade`) — exige a permissão
 * sistema-configuracao.editar_configuracoes.
 */
data class AssiduidadeConfigRequest(
    val activo: Boolean,
    val configuracao: ConfiguracaoAssiduidade
)
