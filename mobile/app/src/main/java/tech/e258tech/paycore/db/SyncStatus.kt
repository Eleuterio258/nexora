package tech.e258tech.paycore.db

/**
 * Estado de sincronização de um registo pendente (venda/estorno/sessão de caixa) — ver
 * TransacaoPDVEntity/SessaoCaixaEntity/EstornoEntity. Aditivo aos booleanos existentes
 * (syncPendente/sincronizado/aberturaSincronizada+fechoSincronizado), que continuam a ser
 * a fonte de verdade de "já terminou ou não" — isto só classifica PORQUÊ ainda não terminou.
 *
 * - PENDENTE: nunca tentado.
 * - EM_RETRY: já falhou pelo menos uma vez, mas é uma falha transitória (rede, 5xx) — o
 *   SyncWorker continua a tentar nas próximas rondas.
 * - FALHADO: falha permanente (ex.: rejeição de regra de negócio do backend, 4xx) — deixa de
 *   ser tentado automaticamente até haver uma alteração externa (ex.: correcção manual).
 * - SINCRONIZADO: concluído com sucesso.
 */
object SyncStatus {
    const val PENDENTE = "PENDENTE"
    const val EM_RETRY = "EM_RETRY"
    const val FALHADO = "FALHADO"
    const val SINCRONIZADO = "SINCRONIZADO"
}
