-- Fase 6: parcelas + referência bancária

-- 6.3 Parcelas de cobranças
CREATE TABLE IF NOT EXISTS gestao_escolar.school_fee_installments (
    id              bigserial    PRIMARY KEY,
    tenant_id       bigint       NOT NULL,
    fee_id          bigint       NOT NULL REFERENCES gestao_escolar.school_fees(id) ON DELETE CASCADE,
    numero          int          NOT NULL,          -- 1, 2, 3...
    valor           numeric(12,2) NOT NULL,
    data_vencimento date         NOT NULL,
    status          varchar(20)  NOT NULL DEFAULT 'pendente',
    pago_em         timestamptz,
    created_at      timestamptz  NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, fee_id, numero),
    CHECK (status IN ('pendente','paga','cancelada'))
);

-- 6.2 Referência bancária automática na emissão
ALTER TABLE gestao_escolar.school_fees
    ADD COLUMN IF NOT EXISTS banco_entidade  varchar(20),
    ADD COLUMN IF NOT EXISTS banco_referencia varchar(40);

-- 6.4 Bolsas/isenções: o campo aprovado_por já existe, adicionar estado de aprovação
ALTER TABLE gestao_escolar.school_student_fee_discounts
    ADD COLUMN IF NOT EXISTS estado varchar(20) NOT NULL DEFAULT 'aprovado',
    ADD COLUMN IF NOT EXISTS criado_por bigint REFERENCES auth.users(id);
