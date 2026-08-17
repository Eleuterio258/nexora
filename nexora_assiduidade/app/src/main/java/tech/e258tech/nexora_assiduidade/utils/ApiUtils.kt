package tech.e258tech.nexora_assiduidade.utils

import com.google.gson.Gson
import com.google.gson.JsonObject
import retrofit2.Response

object ApiUtils {

    private val gson = Gson()

    fun bearerToken(token: String): String = "Bearer $token"

    /** true se o backend recusou o pedido com 403. */
    fun isForbidden(response: Response<*>): Boolean = response.code() == 403

    fun errorMessage(response: Response<*>): String {
        val detalhe = detalheDoErro(response)
        if (detalhe != null) {
            return detalhe
        }

        // Um 403 sem detalhe no corpo e, na pratica, RBAC: o middleware
        // RequirePermission do ERP corta o pedido antes de chegar ao handler.
        // Quando o corpo traz mensagem, o 403 pode ser outra coisa
        // completamente — consentimento LGPD em falta, metodo facial
        // desactivado no tenant, ou o FaceClock a recusar o enrollment (o ERP
        // propaga o status dele) — e nesses casos dizer "sem permissao"
        // esconde o motivo real ao gestor.
        if (isForbidden(response)) {
            return "Sem permissão para este ecrã."
        }

        return "Falha na comunicacao com o servidor."
    }

    /**
     * Extrai a mensagem de erro do corpo da resposta, ou null se o corpo
     * estiver vazio ou não trouxer mensagem utilizável.
     */
    private fun detalheDoErro(response: Response<*>): String? {
        val body = response.errorBody()?.string().orEmpty()
        if (body.isBlank()) {
            return null
        }

        return runCatching {
            val json = gson.fromJson(body, JsonObject::class.java)
            // "detail" e o formato de erro do FaceClock (FastAPI); "error" e o
            // do Nexora ERP (Go) — desde 2026-07-13 varios ecras falam
            // directamente com o ERP, por isso tem de aceitar os dois.
            json.get("detail")?.asString ?: json.get("error")?.asString
        }.getOrNull()?.takeIf { it.isNotBlank() }
    }

    /**
     * Erro no formato RFC 6749 usado pelo Authorization Server OAuth2
     * (/oauth/token): {"error":"invalid_grant","error_description":"..."}.
     * Devolve a descrição amigável quando disponível; fallback para [errorMessage].
     */
    fun oauthErrorMessage(response: Response<*>): String {
        val body = response.errorBody()?.string().orEmpty()
        if (body.isBlank()) {
            return errorMessage(response)
        }
        return runCatching {
            val json = gson.fromJson(body, JsonObject::class.java)
            json.get("error_description")?.asString ?: json.get("error")?.asString
        }.getOrNull().orEmpty().ifBlank {
            errorMessage(response)
        }
    }
}
