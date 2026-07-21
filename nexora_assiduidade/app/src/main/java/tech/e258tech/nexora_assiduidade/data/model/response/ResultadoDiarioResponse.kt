package tech.e258tech.nexora_assiduidade.data.model.response

/**
 * Resultado diário já calculado (modelo novo), tal como devolvido por
 * GET /api/rh/funcionarios/{id}/resultados no Nexora ERP
 * (`ListarResultadosFuncionario`, backend/internal/modules/recursos-humanos/handlers/resultados_assiduidade.go).
 *
 * Os campos `horas_*` vêm em NANOSSEGUNDOS (Long), não como string "8h0m0s":
 * `time.Duration` em Go é só um `int64` e não tem `MarshalJSON` próprio, por
 * isso o `encoding/json` do backend serializa-o como número puro. Confirmado
 * empiricamente (ver `horas_trabalhadas: 28800000000000` = 8h para um dia com
 * entrada/saída reais). Usar `formatNanosAsHours` para apresentar ao utilizador.
 */
data class ResultadoDiarioResponse(
    val data_referencia: String,
    val horas_trabalhadas: Long?,
    val horas_normais: Long?,
    val horas_extra: Long?,
    val horas_nocturnas: Long?,
    val horas_remoto: Long?,
    val horas_missao: Long?,
    val horas_formacao: Long?,
    val horas_intervalo: Long?,
    val horas_nao_contabilizadas: Long?,
    val atraso_minutos: Int,
    val saida_antecipada_minutos: Int,
    val ausencia: Boolean,
    val falta_justificada: Boolean,
    val falta_injustificada: Boolean,
    val versao_regra: Int,
    val recalculado_em: String?
) {
    companion object {
        /** Formata nanossegundos como "8h00" (ou "0h00" quando nulo/zero). */
        fun formatNanosAsHours(nanos: Long?): String {
            if (nanos == null || nanos <= 0L) return "0h00"
            val totalMinutes = nanos / 60_000_000_000L
            return "%dh%02d".format(totalMinutes / 60, totalMinutes % 60)
        }
    }
}
