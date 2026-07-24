SET search_path TO impostos, public;

-- ── Grupos de Imposto ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tax_groups (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tax_groups UNIQUE (tenant_id, codigo)
);

-- ── Taxas: ligação opcional a um grupo de imposto ───────────────────────────
ALTER TABLE taxes
    ADD COLUMN IF NOT EXISTS tax_group_id BIGINT REFERENCES tax_groups(id);

CREATE INDEX IF NOT EXISTS idx_taxes_tax_group
    ON taxes (tenant_id, tax_group_id);

-- ── Regras de Taxa (faixas progressivas) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS tax_rules (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tax_id BIGINT NOT NULL,
    valor_minimo NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_maximo NUMERIC(18,2),
    taxa NUMERIC(8,4) NOT NULL DEFAULT 0,
    ordem INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tax_rules_tax FOREIGN KEY (tax_id) REFERENCES taxes(id) ON DELETE CASCADE,
    CONSTRAINT chk_tax_rules_intervalo CHECK (valor_maximo IS NULL OR valor_maximo > valor_minimo),
    CONSTRAINT chk_tax_rules_taxa CHECK (taxa >= 0)
);

CREATE INDEX IF NOT EXISTS idx_tax_rules_tax
    ON tax_rules (tax_id, valor_minimo);
