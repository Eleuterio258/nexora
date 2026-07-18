package tech.e258tech.nexora_assiduidade.utils

import com.google.gson.Gson
import com.google.gson.JsonObject
import retrofit2.Response

object ApiUtils {

    private val gson = Gson()

    fun bearerToken(token: String): String = "Bearer $token"

    /** true se o backend recusou o pedido por falta de permissão RBAC (auth.permissoes_cargo). */
    fun isForbidden(response: Response<*>): Boolean = response.code() == 403

    fun errorMessage(response: Response<*>): String {
        if (isForbidden(response)) {
            return "Sem permissão para este ecrã."
        }

        val body = response.errorBody()?.string().orEmpty()
        if (body.isBlank()) {
            return "Falha na comunicacao com o servidor."
        }

        return runCatching {
            val json = gson.fromJson(body, JsonObject::class.java)
            // "detail" e o formato de erro do FaceClock (FastAPI); "error" e o
            // do Nexora ERP (Go) — desde 2026-07-13 varios ecras falam
            // directamente com o ERP, por isso tem de aceitar os dois.
            json.get("detail")?.asString ?: json.get("error")?.asString
        }.getOrNull().orEmpty().ifBlank {
            "Falha na comunicacao com o servidor."
        }
    }
}
