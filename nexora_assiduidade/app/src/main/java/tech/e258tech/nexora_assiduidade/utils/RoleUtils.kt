package tech.e258tech.nexora_assiduidade.utils

object RoleUtils {

    fun isManager(role: String?): Boolean {
        return role == Constants.ROLE_GESTOR || role == Constants.ROLE_ADMIN
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
