SET search_path TO contabilidade, public;

-- ── Anos Fiscais ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fiscal_years (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto'
        CHECK (status IN ('aberto','fechado')),
    fechado_em TIMESTAMPTZ,
    fechado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fiscal_years UNIQUE (tenant_id, ano)
);

-- ── Períodos Fiscais: accounting_periods passa a fiscal_periods ────────────
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
         WHERE table_schema='contabilidade' AND table_name='accounting_periods'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.tables
         WHERE table_schema='contabilidade' AND table_name='fiscal_periods'
    ) THEN
        ALTER TABLE accounting_periods RENAME TO fiscal_periods;
    END IF;
END $$;

ALTER TABLE fiscal_periods
    ADD COLUMN IF NOT EXISTS fiscal_year_id BIGINT REFERENCES fiscal_years(id);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema='contabilidade' AND table_name='fiscal_periods'
           AND column_name='mes' AND is_nullable='YES'
    ) THEN
        ALTER TABLE fiscal_periods ALTER COLUMN mes SET NOT NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_fiscal_periods_fiscal_year
    ON fiscal_periods (fiscal_year_id);

-- ── Lançamentos: accounting_period_id passa a fiscal_period_id ─────────────
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema='contabilidade' AND table_name='journal_entries'
           AND column_name='accounting_period_id'
    ) THEN
        ALTER TABLE journal_entries RENAME COLUMN accounting_period_id TO fiscal_period_id;
    END IF;
END $$;
