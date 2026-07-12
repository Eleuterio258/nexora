package tech.e258tech.nexora_assiduidade.data.model

/**
 * GET /api/rh/relatorios (ERP, Go) — ver
 * backend/internal/modules/recursos-humanos/handlers/relatorios.go:42
 * (`RelatoriosRH`). Única fonte de relatórios usada pelo app de gestor — o
 * FaceClock deixou de expor relatórios próprios (arquitectura stateless).
 */
data class RelatorioRH(
    val total_funcionarios: Int,
    val por_estado: List<NomeContagem>,
    val por_unidade: List<NomeContagem>,
    val por_cargo: List<NomeContagem>,
    val absentismo: List<AbsentismoResumo>,
    val processos_disciplinares: Map<String, Int>,
    val formacoes: Map<String, Int>,
    val pode_ver_salarios: Boolean
)

data class NomeContagem(val nome: String? = null, val estado: String? = null, val total: Int) {
    val label: String get() = nome ?: estado ?: "-"
}

data class AbsentismoResumo(val tipo: String, val total: Int, val dias: Double)
