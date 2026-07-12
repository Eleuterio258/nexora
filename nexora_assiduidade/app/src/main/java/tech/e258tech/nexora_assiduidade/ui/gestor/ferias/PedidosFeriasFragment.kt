package tech.e258tech.nexora_assiduidade.ui.gestor.ferias

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
import tech.e258tech.nexora_assiduidade.data.model.Ausencia
import tech.e258tech.nexora_assiduidade.data.network.RetrofitClient
import tech.e258tech.nexora_assiduidade.utils.ApiUtils
import tech.e258tech.nexora_assiduidade.utils.SessionManager

/**
 * Gestão de Pedidos de Férias/Ausências — GET /api/rh/ausencias,
 * POST /api/rh/ausencias/{id}/aprovar|rejeitar (ERP).
 */
class PedidosFeriasFragment : Fragment() {

    private val uiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var token: String? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.gestor_pedidos_ferias, container, false)
    }

    override fun onDestroyView() {
        uiScope.cancel()
        super.onDestroyView()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val recyclerView = view.findViewById<RecyclerView>(R.id.recyclerViewPedidos)
        val tvEmpty = view.findViewById<TextView>(R.id.tvPedidosEmpty)
        recyclerView.layoutManager = LinearLayoutManager(context)

        token = SessionManager(requireContext()).getToken()
        val currentToken = token
        if (currentToken.isNullOrBlank()) {
            tvEmpty.visibility = View.VISIBLE
            tvEmpty.text = "Sessão inválida. Faça login novamente."
            return
        }

        loadPedidos(recyclerView, tvEmpty, currentToken)
    }

    private fun loadPedidos(recyclerView: RecyclerView, tvEmpty: TextView, token: String) {
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    RetrofitClient.erpApiService.getAusencias(ApiUtils.bearerToken(token))
                }

                if (!response.isSuccessful || response.body() == null) {
                    tvEmpty.visibility = View.VISIBLE
                    tvEmpty.text = ApiUtils.errorMessage(response)
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                val items = response.body().orEmpty().toMutableList()
                if (items.isEmpty()) {
                    tvEmpty.visibility = View.VISIBLE
                    recyclerView.visibility = View.GONE
                    return@launch
                }

                tvEmpty.visibility = View.GONE
                recyclerView.visibility = View.VISIBLE
                recyclerView.adapter = PedidosFeriasAdapter(
                    items,
                    onAprovar = { pedido -> resolverPedido(pedido, recyclerView, aprovar = true) },
                    onRejeitar = { pedido -> resolverPedido(pedido, recyclerView, aprovar = false) },
                )
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                tvEmpty.visibility = View.VISIBLE
                tvEmpty.text = "Não foi possível carregar os pedidos."
                recyclerView.visibility = View.GONE
                Toast.makeText(context, "Falha ao consultar o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun resolverPedido(pedido: Ausencia, recyclerView: RecyclerView, aprovar: Boolean) {
        val currentToken = token ?: return
        uiScope.launch {
            try {
                val response = withContext(Dispatchers.IO) {
                    val bearer = ApiUtils.bearerToken(currentToken)
                    if (aprovar) {
                        RetrofitClient.erpApiService.aprovarAusencia(bearer, pedido.id)
                    } else {
                        RetrofitClient.erpApiService.rejeitarAusencia(bearer, pedido.id)
                    }
                }

                if (!response.isSuccessful) {
                    Toast.makeText(context, ApiUtils.errorMessage(response), Toast.LENGTH_LONG).show()
                    return@launch
                }

                Toast.makeText(
                    context,
                    if (aprovar) "Pedido aprovado." else "Pedido rejeitado.",
                    Toast.LENGTH_SHORT
                ).show()
                (recyclerView.adapter as? PedidosFeriasAdapter)?.removeItem(pedido)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isAdded) return@launch
                Toast.makeText(context, "Falha ao comunicar com o ERP.", Toast.LENGTH_LONG).show()
            }
        }
    }
}
