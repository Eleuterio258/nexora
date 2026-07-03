-- Fase 2: campos de cancelamento de cobrança, desconto pendente e lockout portal

-- 2.5 Cancelamento de cobranças com motivo
ALTER TABLE gestao_escolar.school_fees
    ADD COLUMN IF NOT EXISTS cancelamento_motivo text,
    ADD COLUMN IF NOT EXISTS cancelado_em        timestamptz,
    ADD COLUMN IF NOT EXISTS cancelado_por       bigint REFERENCES auth.users(id);

-- 2.4 Desconto pendente de aprovação
ALTER TABLE gestao_escolar.school_fees
    ADD COLUMN IF NOT EXISTS desconto_pendente        numeric(12,2),
    ADD COLUMN IF NOT EXISTS desconto_pendente_motivo text;
