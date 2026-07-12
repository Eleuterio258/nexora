package tech.e258tech.nexora_assiduidade.utils

import tech.e258tech.nexora_assiduidade.data.model.response.ErpModuloAcesso

object RoleUtils {

    fun isManager(role: String?): Boolean {
        return role == Constants.ROLE_GESTOR || role == Constants.ROLE_ADMIN
    }

    /**
     * Traduz a identidade do ERP (tipo + permissões RBAC) para o vocabulário
     * de role usado neste app (COLABORADOR/GESTOR_RH/ADMIN_SISTEMA) — mesma
     * regra usada do lado Go em `gatewayAppRole`
     * (backend/internal/modules/auth/handlers/auth.go), aplicada aqui porque
     * o login agora devolve directamente `modulos`/`acoes` (a app não passa
     * mais pelo gateway/validate no momento do login).
     */
    fun fromErpLogin(tipo: String, modulos: List<ErpModuloAcesso>): String {
        if (tipo == "superadmin") return Constants.ROLE_ADMIN
        val podeAprovarAusencias = modulos.any { it.modulo == "recursos-humanos" && it.acoes.contains("aprovar_ausencias") }
        return if (podeAprovarAusencias) Constants.ROLE_GESTOR else Constants.ROLE_FUNCIONARIO
    }

    fun displayName(role: String?): String {
        return when (role) {
            Constants.ROLE_ADMIN -> "Administrador do Sistema"
            Constants.ROLE_GESTOR -> "Gestor de RH"
            Constants.ROLE_FUNCIONARIO -> "Colaborador"
            else -> role ?: "Utilizador"
        }
    }
}
