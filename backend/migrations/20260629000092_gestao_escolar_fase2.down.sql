-- ============================================================
-- Down migration 092 (antiga 093): remove colunas de cancelamento/desconto
-- ============================================================

SET search_path TO gestao_escolar, public;

ALTER TABLE school_fees
    DROP COLUMN IF EXISTS cancelamento_motivo,
    DROP COLUMN IF EXISTS cancelado_em,
    DROP COLUMN IF EXISTS cancelado_por,
    DROP COLUMN IF EXISTS desconto_pendente,
    DROP COLUMN IF EXISTS desconto_pendente_motivo;
