package tech.e258tech.nexora_assiduidade.utils

import tech.e258tech.nexora_assiduidade.data.model.response.ErpModuloAcesso

object RoleUtils {

    fun isManager(role: String?): Boolean {
        return role == Constants.ROLE_GESTOR
    }

    /**
     * Traduz a identidade do ERP (permissões RBAC) para o vocabulário de role
     * usado neste app (COLABORADOR/GESTOR_RH). Só existe um tipo de
     * utilizador do lado do backend para esta app — o que distingue
     * Colaborador de Gestor é exclusivamente o acesso que tem nos módulos
     * (`recursos-humanos:aprovar_ausencias`), não um `tipo` separado.
     */
    fun fromErpLogin(modulos: List<ErpModuloAcesso>): String {
        val podeAprovarAusencias = modulos.any { it.modulo == "recursos-humanos" && it.acoes.contains("aprovar_ausencias") }
        return if (podeAprovarAusencias) Constants.ROLE_GESTOR else Constants.ROLE_FUNCIONARIO
    }

    fun displayName(role: String?): String {
        return when (role) {
            Constants.ROLE_GESTOR -> "Gestor de RH"
            Constants.ROLE_FUNCIONARIO -> "Colaborador"
            else -> role ?: "Utilizador"
        }
    }
}
