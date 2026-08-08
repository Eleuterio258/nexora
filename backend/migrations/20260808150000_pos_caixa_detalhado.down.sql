DROP TABLE IF EXISTS pos.pos_cash_movements;

ALTER TABLE pos.pos_sessions
    DROP COLUMN IF EXISTS contagem_notas,
    DROP COLUMN IF EXISTS justificativa_diferenca;
