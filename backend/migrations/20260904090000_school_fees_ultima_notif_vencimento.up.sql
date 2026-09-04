-- Repõe a coluna que o job notifCobrancasVencidas (internal/background/jobs.go)
-- lê e escreve para não reenviar o mesmo aviso de atraso mais do que uma vez
-- por dia. Foi criada em archive/20260629000083_escola_notif_fase4.up.sql mas
-- não chegou ao baseline de 2026-07-24, por isso o job falhava em todas as
-- execuções com "column f.ultima_notif_vencimento does not exist" e nunca
-- chegou a enviar um único aviso.
ALTER TABLE gestao_escolar.school_fees
    ADD COLUMN IF NOT EXISTS ultima_notif_vencimento timestamptz;

CREATE INDEX IF NOT EXISTS idx_school_fees_notif_venc
    ON gestao_escolar.school_fees (tenant_id, status, data_vencimento)
    WHERE status IN ('emitida', 'parcial');
