package tech.e258tech.nexora_assiduidade.utils

import com.google.gson.Gson
import com.google.gson.JsonObject
import retrofit2.Response

object ApiUtils {

    private val gson = Gson()

    fun bearerToken(token: String): String = "Bearer $token"

    fun errorMessage(response: Response<*>): String {
        val body = response.errorBody()?.string().orEmpty()
        if (body.isBlank()) {
            return "Falha na comunicacao com o servidor."
        }

        return runCatching {
            gson.fromJson(body, JsonObject::class.java).get("detail")?.asString
        }.getOrNull().orEmpty().ifBlank {
            "Falha na comunicacao com o servidor."
        }
    }
}
