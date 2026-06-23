package tech.e258tech.nexora_mobile.utils

sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val message: String, val code: Int = 0) : Result<Nothing>()
    data object Loading : Result<Nothing>()

    val isSuccess get() = this is Success
    val isError   get() = this is Error

    fun getOrNull(): T? = (this as? Success)?.data
}

// Converte Response<T> do Retrofit em Result<T>
suspend fun <T> safeApiCall(call: suspend () -> retrofit2.Response<T>): Result<T> {
    return try {
        val response = call()
        if (response.isSuccessful) {
            val body = response.body()
            if (body != null) Result.Success(body)
            else Result.Error("Resposta vazia", response.code())
        } else {
            val errorMsg = response.errorBody()?.string() ?: "Erro ${response.code()}"
            Result.Error(errorMsg, response.code())
        }
    } catch (e: java.net.UnknownHostException) {
        Result.Error("Sem ligação à internet")
    } catch (e: java.net.ConnectException) {
        Result.Error("Não foi possível ligar ao servidor")
    } catch (e: Exception) {
        Result.Error(e.message ?: "Erro desconhecido")
    }
}
