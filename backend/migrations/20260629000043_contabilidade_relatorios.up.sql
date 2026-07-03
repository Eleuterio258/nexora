SET search_path TO contabilidade, public;

CREATE TABLE IF NOT EXISTS accounting_reports (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    parametros JSONB NOT NULL DEFAULT '{}'::jsonb,
    conteudo JSONB NOT NULL DEFAULT '{}'::jsonb,
    gerado_por BIGINT,
    gerado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_accounting_reports_tipo CHECK (tipo IN (
        'trial_balance','balance_sheet','income_statement',
        'general_ledger','depreciation_summary','budget_execution'
    ))
);

CREATE INDEX IF NOT EXISTS idx_accounting_reports_tenant ON accounting_reports (tenant_id, tipo, gerado_em DESC);
