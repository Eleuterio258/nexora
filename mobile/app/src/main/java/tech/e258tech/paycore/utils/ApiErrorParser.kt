package tech.e258tech.paycore.utils

import com.google.gson.Gson
import retrofit2.Response

/**
 * Extrai a mensagem de erro legível de respostas do backend Nexora (Go).
 *
 * O Nexora devolve erros tipicamente como:
 *   {"error":"Terminal sem armazém configurado"}
 *   {"error":"Série FT não configurada"}
 *   {"message":"Outro formato"}
 *
 * Esta classe normaliza esses formatos numa String amigável, e reconhece
 * erros operacionais comuns do POS para poder sugerir a acção correcta.
 */
object ApiErrorParser {

    private val gson = Gson()

    data class ParsedError(
        val rawMessage: String,
        val userMessage: String,
        val isOperational: Boolean
    )

    fun parse(response: Response<*>?): ParsedError {
        val raw = extractRawMessage(response)
        return parse(raw)
    }

    fun parse(throwable: Throwable?): ParsedError {
        val raw = throwable?.message ?: "Erro desconhecido"
        return parse(raw)
    }

    /** true se a mensagem crua corresponder ao 403 "funcionário não autorizado a operar este
     * terminal" (ver Plano_Correcao_Gaps_Criticos_POS.md, Fase 3) — distinto de um 403 genérico
     * de permissão RBAC revogada, que deve continuar a passar por PermissaoHelper.aoReceber403
     * em vez de mostrar esta mensagem. */
    fun isFalhaAutorizacaoTerminal(rawMessage: String?): Boolean {
        val normalized = rawMessage?.lowercase().orEmpty()
        return normalized.contains("autorizado") && normalized.contains("terminal")
    }

    fun parse(rawMessage: String?): ParsedError {
        val raw = rawMessage?.trim()?.takeIf { it.isNotBlank() } ?: "Erro desconhecido"
        val normalized = raw.lowercase()

        return when {
            normalized.contains("armazém") || normalized.contains("warehouse") -> ParsedError(
                rawMessage = raw,
                userMessage = "Terminal não tem armazém associado.\n\nConfigure no painel Nexora:\nPOS → Terminais → editar terminal → seleccionar armazém.",
                isOperational = true
            )
            normalized.contains("série") && normalized.contains("ft") -> ParsedError(
                rawMessage = raw,
                userMessage = "Série de faturas (FT) não configurada.\n\nConfigure no painel Nexora:\nFaturação → Séries Documentais → criar série FT activa.",
                isOperational = true
            )
            normalized.contains("sem permissão") || normalized.contains("permission") -> ParsedError(
                rawMessage = raw,
                userMessage = "Sem permissão para esta operação.\n\nInicie sessão com um utilizador que tenha o perfil adequado, ou peça ao administrador para configurar as permissões.",
                isOperational = true
            )
            // 403 — funcionário sem atribuição em pos.terminal_funcionarios para este terminal
            // (ver Plano_Correcao_Gaps_Criticos_POS.md, Fase 3). Verificar "terminal" primeiro
            // para não cair no caso genérico de "sem permissão" acima, que não diz qual é a acção.
            isFalhaAutorizacaoTerminal(raw) -> ParsedError(
                rawMessage = raw,
                userMessage = "Este operador não está autorizado a usar este terminal.\n\nPeça ao administrador para o associar ao terminal no painel Nexora (Terminais → Operadores autorizados).",
                isOperational = true
            )
            // 409 — já existe sessão aberta NESTE terminal (índice único por terminal, Fase 3),
            // distinto do caso abaixo (sessão aberta pelo mesmo utilizador, já suportado hoje).
            // Tem de vir antes por ser mais específico — "terminal" é a palavra que distingue.
            normalized.contains("sessão") && normalized.contains("aberta") && normalized.contains("terminal") -> ParsedError(
                rawMessage = raw,
                userMessage = "Já existe uma sessão de caixa aberta para este terminal.\n\nPeça a quem a abriu para a fechar, ou contacte o supervisor.",
                isOperational = true
            )
            normalized.contains("sessão de caixa aberta") || normalized.contains("já tem") -> ParsedError(
                rawMessage = raw,
                userMessage = "Já existe uma sessão de caixa aberta para este terminal. Feche a sessão anterior antes de abrir uma nova.",
                isOperational = true
            )
            normalized.contains("pin inválido") -> ParsedError(
                rawMessage = raw,
                userMessage = "PIN incorrecto. Verifique o PIN configurado para o operador no painel Nexora.",
                isOperational = true
            )
            normalized.contains("credenciais") -> ParsedError(
                rawMessage = raw,
                userMessage = "Credenciais inválidas. Verifique o email e a senha.",
                isOperational = true
            )
            normalized.contains("terminal inativo") || normalized.contains("não está ativo") -> ParsedError(
                rawMessage = raw,
                userMessage = "Terminal inativo. Contacte o administrador para activar o terminal no painel Nexora.",
                isOperational = true
            )
            else -> ParsedError(
                rawMessage = raw,
                userMessage = raw,
                isOperational = false
            )
        }
    }

    private fun extractRawMessage(response: Response<*>?): String {
        val bodyString = response?.errorBody()?.string()?.trim()
        if (!bodyString.isNullOrBlank()) {
            return try {
                val json = gson.fromJson(bodyString, Map::class.java) as? Map<*, *>
                json?.get("error")?.toString()
                    ?: json?.get("message")?.toString()
                    ?: bodyString
            } catch (_: Exception) {
                bodyString
            }
        }
        return response?.message()?.takeIf { it.isNotBlank() } ?: "Erro ${response?.code()}"
    }
}
