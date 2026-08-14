package tech.e258tech.paycore.utils

import android.app.Activity
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import retrofit2.Response
import tech.e258tech.paycore.api.ApiClient
import tech.e258tech.paycore.api.Permissoes
import tech.e258tech.paycore.repository.SessionRepository

object PermissaoHelper {

    /**
     * Lança SemPermissaoException se a resposta for 403.
     * Deve ser chamado antes de .body() para que o repository possa propagar o erro.
     */
    fun <T> Response<T>.lancarSeSemPermissao() {
        if (code() == 403) throw SemPermissaoException("Sem permissão")
    }

    /**
     * Retorna o body se a resposta for bem-sucedida, mas lança SemPermissaoException
     * antes se o código for 403.
     */
    fun <T> Response<T>.bodyOuSemPermissao(): T? {
        lancarSeSemPermissao()
        return body()
    }

    /**
     * Verifica se um Result falhou por 403 e, nesse caso, fecha a activity e actualiza permissões.
     */
    fun <T> Result<T>.tratarSemPermissao(activity: ComponentActivity): Result<T> {
        if (isFailure && exceptionOrNull() is SemPermissaoException) {
            aoReceber403(activity)
        }
        return this
    }

    /**
     * Verifica se o funcionário tem a permissão necessária.
     * Se não tiver, mostra mensagem e fecha a activity.
     */
    fun Activity.verificarPermissaoOuFechar(modulo: String, permissao: String): Boolean {
        val tem = SessionRepository.temPermissao(modulo, permissao)
        if (!tem) {
            Toast.makeText(this, "Sem permissão para aceder a esta função.", Toast.LENGTH_LONG).show()
            finish()
        }
        return tem
    }

    /**
     * Mostra mensagem de sem permissão e fecha a activity atual.
     */
    fun mostrarSemPermissaoEFechar(activity: Activity) {
        Toast.makeText(activity, "Sem permissão para aceder a esta função.", Toast.LENGTH_LONG).show()
        activity.finish()
    }

    /**
     * Chamado quando o ERP responde 403. Atualiza as permissões do funcionário
     * e fecha a activity se a permissão foi revogada.
     */
    fun aoReceber403(activity: ComponentActivity) {
        if (activity.isFinishing || activity.isDestroyed) return

        Toast.makeText(activity, "Permissão revogada. Actualizando permissões...", Toast.LENGTH_SHORT).show()

        activity.lifecycleScope.launch {
            val resposta = runCatching { ApiClient.service.meAcesso() }.getOrNull()
            val modulos = resposta?.body()?.modulos
            if (modulos != null) {
                SessionRepository.atualizarPermissoes(modulos)
            }
            if (activity.isFinishing || activity.isDestroyed) return@launch
            Toast.makeText(activity, "Sem permissão para continuar.", Toast.LENGTH_LONG).show()
            activity.finish()
        }
    }

    /**
     * Verifica se o funcionário pode operar o POS (vendas, caixa, pagamentos).
     */
    fun podeOperarPos(): Boolean = SessionRepository.temPermissao(Permissoes.MODULO_POS, Permissoes.OPERAR_POS)

    /**
     * Verifica se o funcionário pode gerir terminais.
     */
    fun podeGerirTerminais(): Boolean = SessionRepository.temPermissao(Permissoes.MODULO_POS, Permissoes.GERIR_TERMINAIS)

    /**
     * Verifica se o funcionário pode gerir o catálogo (produtos/categorias).
     */
    fun podeGerirCatalogo(): Boolean = SessionRepository.temPermissao(Permissoes.MODULO_POS, Permissoes.GERIR_CATALOGO)

    /**
     * Verifica se o funcionário pode gerir descontos.
     */
    fun podeGerirDescontos(): Boolean = SessionRepository.temPermissao(Permissoes.MODULO_POS, Permissoes.GERIR_DESCONTOS)

    /**
     * Verifica se o funcionário tem permissões de supervisor/gerente no POS
     * (cancelamentos, estornos parciais, movimentos de caixa).
     */
    fun podeSupervisionarPos(): Boolean = SessionRepository.temPermissao(Permissoes.MODULO_POS, Permissoes.SUPERVISIONAR_POS)
}
