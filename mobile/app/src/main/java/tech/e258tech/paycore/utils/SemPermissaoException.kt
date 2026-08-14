package tech.e258tech.paycore.utils

/**
 * Exceção lançada quando o ERP responde 403 (Sem permissão).
 */
class SemPermissaoException(message: String = "Sem permissão") : SecurityException(message)
