-- Liga rh.justificacoes ao registo de presença real que justificam.
-- Antes desta migration, aprovar uma justificação (quando isso passar a ser
-- possível) não teria nenhum efeito sobre rh.presencas: ResumoAssiduidade/
-- MinhaAssiduidade contam atrasos/faltas directamente de rh.presencas.tipo,
-- sem nenhuma forma de saber que uma falta/atraso já foi justificada.

BEGIN;

ALTER TABLE rh.presencas
    ADD COLUMN IF NOT EXISTS justificado boolean DEFAULT false NOT NULL;

COMMENT ON COLUMN rh.presencas.justificado IS
    'Marcado quando uma justificação (rh.justificacoes) para este dia é aprovada — '
    'exclui o dia das contagens de atrasos/faltas em ResumoAssiduidade/Home, sem '
    'apagar o registo original de assiduidade.';

COMMIT;
