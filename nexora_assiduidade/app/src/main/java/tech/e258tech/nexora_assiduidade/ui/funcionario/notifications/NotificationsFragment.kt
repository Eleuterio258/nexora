package tech.e258tech.nexora_assiduidade.ui.funcionario.notifications

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import tech.e258tech.nexora_assiduidade.R
import tech.e258tech.nexora_assiduidade.data.model.Notification
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Centro de notificações do funcionário — GET /api/utilizadores/{userId}/notifications
 * (backend/internal/modules/utilizadores/handlers/notificacoes.go).
 */
class NotificationsFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var sessionManager: SessionManager

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.funcionario_notifications, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        sessionManager = SessionManager(requireContext())

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewNotifications)
        val tvEmpty = view.findViewById<TextView>(R.id.tvEmptyNotifications)
        recyclerView.layoutManager = LinearLayoutManager(context)

        val token = sessionManager.getToken()
        val userId = sessionManager.getUserId()
        if (token.isNullOrBlank() || userId.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        loadNotifications(recyclerView, tvEmpty, token, userId)
    }

    private fun loadNotifications(recyclerView: RecyclerView, tvEmpty: TextView, token: String, userId: String) {
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getNotifications(
                        ApiUtils.bearerToken(token),
                        userId
                    )
                }

                if (!isAdded) return@launch

                if (!response.isSuccessful || response.body() == null) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = ApiUtils.errorMessage(response)
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                val items = response.body().orEmpty()
                if (items.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = "Nenhuma notificação"
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                tvEmpty.visibility = View.GONE
                recyclerView.visibility = View.VISIBLE
                recyclerView.adapter = NotificationAdapter(items) { notification ->
                    marcarComoLida(notification, token, userId)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar as notificações."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun marcarComoLida(notification: Notification, token: String, userId: String) {
        if (notification.lida) return
        uiScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.markNotificationRead(
                        ApiUtils.bearerToken(token),
                        userId,
                        notification.id
                    )
                }
            } catch (_: Exception) {
                // Falha silenciosa — não é crítico para a leitura da notificação no ecrã.
            }
        }
    }
}
