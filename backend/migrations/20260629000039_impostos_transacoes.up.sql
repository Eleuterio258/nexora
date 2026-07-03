SET search_path TO impostos, public;

-- ── Transações de Imposto ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tax_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tax_id BIGINT NOT NULL,
    referencia_tipo VARCHAR(30) NOT NULL,
    referencia_id BIGINT,
    fiscal_period_id BIGINT,
    base_tributavel NUMERIC(18,2) NOT NULL DEFAULT 0,
    taxa_aplicada NUMERIC(8,4) NOT NULL DEFAULT 0,
    valor_imposto NUMERIC(18,2) NOT NULL DEFAULT 0,
    transaction_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tax_transactions_tax FOREIGN KEY (tax_id) REFERENCES taxes(id),
    CONSTRAINT fk_tax_transactions_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id),
    CONSTRAINT chk_tax_transactions_base CHECK (base_tributavel >= 0),
    CONSTRAINT chk_tax_transactions_valor CHECK (valor_imposto >= 0)
);

CREATE INDEX IF NOT EXISTS idx_tax_transactions_tenant ON tax_transactions (tenant_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_tax ON tax_transactions (tax_id);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_ref ON tax_transactions (referencia_tipo, referencia_id);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_period ON tax_transactions (fiscal_period_id);
