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

/** GET /api/rh/funcionarios/{id} — envelope ERP com o funcionário e dados relacionados.
 *  Ver backend/internal/modules/recursos-humanos/handlers/rh.go:387 (ObterFuncionario).
 */
data class FuncionarioDetalhe(
    val funcionario: FuncionarioInfo,
    val contratos: List<ContratoDetalhe>? = null,
    val ausencias: List<AusenciaDetalhe>? = null,
    val avaliacoes: List<AvaliacaoDetalhe>? = null,
    val contactos_emergencia: List<ContactoEmergenciaDetalhe>? = null,
    val documentos: List<DocumentoDetalhe>? = null,
    val pode_aprovar: Boolean = false,
    val pode_ver_salarios: Boolean = false
)

data class FuncionarioInfo(
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

data class ContratoDetalhe(
    val id: Long,
    val tipo: String,
    val funcao: String?,
    val data_inicio: String?,
    val data_fim: String?,
    val salario: Double?,
    val ficheiro_url: String?,
    val estado: String
)

data class AusenciaDetalhe(
    val id: Long,
    val tipo_id: Long?,
    val tipo_nome: String?,
    val data_inicio: String?,
    val data_fim: String?,
    val dias: Int?,
    val motivo: String?,
    val estado: String,
    val aprovado_em: String?
)

data class AvaliacaoDetalhe(
    val id: Long,
    val periodo_id: Long?,
    val periodo_nome: String?,
    val pontuacao: Double?,
    val comentarios: String?,
    val estado: String,
    val created_at: String?,
    val criterios: List<AvaliacaoCriterioDetalhe>? = null,
    val pode_submeter: Boolean = false
)

data class AvaliacaoCriterioDetalhe(
    val criterio_id: Long?,
    val criterio_nome: String?,
    val pontuacao: Double?,
    val peso: Double?
)

data class ContactoEmergenciaDetalhe(
    val id: Long,
    val nome: String,
    val parentesco: String?,
    val telefone: String,
    val email: String?
)

data class DocumentoDetalhe(
    val id: Long,
    val tipo: String,
    val numero: String?,
    val data_emissao: String?,
    val data_validade: String?,
    val ficheiro_url: String?
)

data class FuncionarioListMeta(val total: Int, val page: Int, val limit: Int)

/** Envelope paginado devolvido quando `page`/`limit` são enviados; sem eles, o
 * ERP devolve um array simples (ver `ListarFuncionarios`). Este app envia
 * sempre paginação, para ter sempre o mesmo formato de resposta. */
data class FuncionarioListResponse(
    val data: List<Funcionario>,
    val meta: FuncionarioListMeta
)
