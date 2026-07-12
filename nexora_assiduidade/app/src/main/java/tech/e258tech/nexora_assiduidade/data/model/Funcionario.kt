package tech.e258tech.nexora_assiduidade.data.model

/**
 * Linha de GET /api/rh/funcionarios (ERP, Go) — ver
 * backend/internal/modules/recursos-humanos/handlers/rh.go:190 (`Row`).
 */
data class Funcionario(
    val id: Long,
    val numero_funcionario: String?,
    val nome_completo: String,
    val unit_id: Long?,
    val unidade_nome: String?,
    val cargo: String?,
    val cargo_id: Long?,
    val horario_id: Long?,
    val data_admissao: String?,
    val tipo_contrato: String,
    val estado: String,
    val user_id: Long?
)

/** GET /api/rh/funcionarios/{id} — inclui contratos e ausências do funcionário. */
data class FuncionarioDetalhe(
    val id: Long,
    val numero_funcionario: String?,
    val nome_completo: String,
    val data_nascimento: String?,
    val genero: String?,
    val nuit: String?,
    val telefone: String?,
    val email: String?,
    val endereco: String?,
    val provincia: String?,
    val cidade: String?,
    val bairro: String?,
    val unit_id: Long?,
    val unidade_nome: String?,
    val cargo: String?,
    val cargo_id: Long?,
    val horario_id: Long?,
    val data_admissao: String?,
    val data_saida: String?,
    val tipo_contrato: String,
    val salario_base: Double?,
    val estado: String,
    val user_id: Long?,
    val centro_custo_id: Long?
)

data class FuncionarioListMeta(val total: Int, val page: Int, val limit: Int)

/** Envelope paginado devolvido quando `page`/`limit` são enviados; sem eles, o
 * ERP devolve um array simples (ver `ListarFuncionarios`). Este app envia
 * sempre paginação, para ter sempre o mesmo formato de resposta. */
data class FuncionarioListResponse(
    val data: List<Funcionario>,
    val meta: FuncionarioListMeta
)
