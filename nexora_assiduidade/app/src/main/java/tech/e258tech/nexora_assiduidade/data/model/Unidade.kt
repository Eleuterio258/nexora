package tech.e258tech.nexora_assiduidade.data.model

/**
 * Linha de GET /api/rh/unidades (ERP, Go) — ver
 * backend/internal/modules/recursos-humanos/handlers/rh.go:52 (ListarUnidades).
 * Só os campos usados no picker do QR fixo; o endpoint devolve mais campos.
 */
data class Unidade(
    val id: Long,
    val nome: String,
    val ativo: Boolean
)
