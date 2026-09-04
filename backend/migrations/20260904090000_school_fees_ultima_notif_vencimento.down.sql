DROP INDEX IF EXISTS gestao_escolar.idx_school_fees_notif_venc;

ALTER TABLE gestao_escolar.school_fees
    DROP COLUMN IF EXISTS ultima_notif_vencimento;
