SET search_path TO contabilidade, public;

-- ── Sequências de Numeração de Lançamentos ─────────────────────────────────
CREATE TABLE IF NOT EXISTS journal_entry_sequences (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    accounting_journal_id BIGINT NOT NULL REFERENCES accounting_journals(id) ON DELETE CASCADE,
    ano INTEGER NOT NULL,
    proxima_sequencia INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT uq_journal_entry_sequences UNIQUE (tenant_id, accounting_journal_id, ano)
);

-- ── Índices de apoio a consultas de lançamentos ────────────────────────────
CREATE INDEX IF NOT EXISTS idx_journal_entries_fiscal_period
    ON journal_entries (tenant_id, fiscal_period_id);
