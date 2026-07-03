-- Fase 4: rastrear última notificação de vencimento por cobrança
ALTER TABLE gestao_escolar.school_fees
    ADD COLUMN IF NOT EXISTS ultima_notif_vencimento timestamptz;

CREATE INDEX IF NOT EXISTS idx_school_fees_notif_venc
    ON gestao_escolar.school_fees(tenant_id, status, data_vencimento)
    WHERE status IN ('emitida','parcial');
