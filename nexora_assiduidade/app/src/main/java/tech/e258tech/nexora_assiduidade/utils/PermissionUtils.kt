package tech.e258tech.nexora_assiduidade.utils

/**
 * Consulta as permissões RBAC finas (modulos[].acoes) devolvidas pelo login
 * do Nexora ERP e persistidas em [SessionManager.getModulos] — ver
 * backend/internal/modules/auth/handlers/authcode.go (issueFuncionarioTokens)
 * e a tabela auth.permissoes_cargo, de onde essas acções vêm.
 *
 * Complementa [RoleUtils], que continua a decidir só o layout de navegação
 * (colaborador vs. gestor); este helper decide visibilidade fina dentro do
 * layout de gestor.
 */
object PermissionUtils {
    fun has(sessionManager: SessionManager, modulo: String, acao: String): Boolean =
        sessionManager.getModulos().any { it.modulo == modulo && it.acoes.contains(acao) }
}
