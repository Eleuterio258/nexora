SET search_path TO contabilidade, public;

CREATE TABLE IF NOT EXISTS accounting_budgets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    chart_account_id BIGINT NOT NULL,
    fiscal_year_id BIGINT NOT NULL,
    mes INTEGER,
    valor_orcamentado NUMERIC(18,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_accounting_budgets_account FOREIGN KEY (chart_account_id) REFERENCES chart_of_accounts(id),
    CONSTRAINT fk_accounting_budgets_year FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(id),
    CONSTRAINT uq_accounting_budgets_conta_ano_mes UNIQUE (tenant_id, chart_account_id, fiscal_year_id, mes),
    CONSTRAINT chk_accounting_budgets_mes CHECK (mes IS NULL OR (mes BETWEEN 1 AND 12)),
    CONSTRAINT chk_accounting_budgets_valor CHECK (valor_orcamentado >= 0)
);

CREATE INDEX IF NOT EXISTS idx_accounting_budgets_tenant ON accounting_budgets (tenant_id, fiscal_year_id);
CREATE INDEX IF NOT EXISTS idx_accounting_budgets_account ON accounting_budgets (chart_account_id);

-- A constraint UNIQUE padrão não impede múltiplas linhas com mes IS NULL
-- (NULL != NULL); este índice parcial garante um único orçamento anual
-- por conta/ano.
CREATE UNIQUE INDEX IF NOT EXISTS uq_accounting_budgets_anual
    ON accounting_budgets (tenant_id, chart_account_id, fiscal_year_id) WHERE mes IS NULL;
