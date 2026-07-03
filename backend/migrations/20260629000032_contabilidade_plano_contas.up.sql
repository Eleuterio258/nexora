SET search_path TO contabilidade, public;

-- ── Tipos de Conta ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS account_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    classe VARCHAR(20) NOT NULL
        CHECK (classe IN ('ativo','passivo','capital','rendimento','gasto')),
    natureza VARCHAR(20) NOT NULL
        CHECK (natureza IN ('devedora','credora')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_account_types UNIQUE (tenant_id, codigo)
);

-- ── Plano de Contas: tipo de conta passa a ser referenciado por FK ──────────
ALTER TABLE chart_of_accounts
    ADD COLUMN IF NOT EXISTS account_type_id BIGINT REFERENCES account_types(id);

ALTER TABLE chart_of_accounts DROP COLUMN IF EXISTS tipo;
ALTER TABLE chart_of_accounts DROP COLUMN IF EXISTS natureza;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema='contabilidade' AND table_name='chart_of_accounts' AND column_name='aceita_movimento'
    ) THEN
        ALTER TABLE chart_of_accounts RENAME COLUMN aceita_movimento TO aceita_lancamento;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_chart_of_accounts_account_type
    ON chart_of_accounts (tenant_id, account_type_id);
