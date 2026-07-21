package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resposta de GET /api/auth/me/acesso no Nexora ERP (Go) — ver
 * `ObterAcessoUtilizador` em backend/internal/modules/auth/handlers/permissoes.go:14,
 * que devolve directamente `models.LoadUserAccess`.
 *
 * Chamado logo após o login (ver [tech.e258tech.nexora_assiduidade.ui.auth.LoginActivity])
 * para obter `modulos` em tempo real, em vez de confiar apenas no `modulos`
 * embutido na resposta de POST /api/auth/login — os dois usam a mesma
 * `LoadUserAccess` internamente, mas foi observado em produção o login a
 * devolver `modulos` vazio/ausente para contas que este endpoint mostra
 * correctamente com permissões (ex.: Directora Geral com `aprovar_ausencias`),
 * o que aponta para o binário do endpoint de login estar desactualizado.
 *
 * Nota: `escopo` aqui é uma String única (ex.: "erp"), ao contrário do
 * `List<String>` devolvido em ErpLoginResponse — formatos diferentes por
 * serem handlers distintos, confirmados separadamente por inspecção real.
 */
data class ErpAcessoResponse(
    val user_id: Long,
    val tenant_id: Long,
    val tipo: String,
    val escopo: String,
    val cargo_id: Long? = null,
    val cargo_nome: String? = null,
    val modulos: List<ErpModuloAcesso> = emptyList(),
    val features: List<String> = emptyList()
)
