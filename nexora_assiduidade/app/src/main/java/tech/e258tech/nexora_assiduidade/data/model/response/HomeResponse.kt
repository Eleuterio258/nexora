package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * GET /api/self-service/home (ERP, Go) — ver
 * backend/internal/modules/self-service/handlers/home.go (Handler.Home).
 * Agregado do ecrã inicial do colaborador: saldo de férias, assiduidade do
 * mês corrente, pedidos pendentes, notificações/comunicados por ler e
 * aniversariantes da semana.
 */
data class HomeResponse(
    val saldo_ferias: SaldoFeriasHome,
    val assiduidade_mes: AssiduidadeMesHome,
    val pedidos_pendentes: Int,
    val notificacoes: List<NotificacaoHome>,
    val comunicados: List<ComunicadoHome>,
    val aniversarios: List<AniversarioHome>
)

data class SaldoFeriasHome(
    val dias_atribuidos: Double,
    val dias_usados: Double,
    val dias_disponiveis: Double
)

data class AssiduidadeMesHome(
    val dias_trabalhados: Int,
    val horas_totais: Double,
    val atrasos: Int,
    val faltas: Int
)

data class NotificacaoHome(
    val id: Long,
    val tipo: String,
    val titulo: String,
    val corpo: String?,
    val link: String?,
    val created_at: String
)

data class ComunicadoHome(
    val id: Long,
    val titulo: String,
    val created_at: String,
    val lido: Boolean
)

data class AniversarioHome(
    val nome: String,
    val dia: Int,
    val mes: Int
)
