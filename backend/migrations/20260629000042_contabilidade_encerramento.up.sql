SET search_path TO contabilidade, public;

CREATE TABLE IF NOT EXISTS period_closings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fiscal_period_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'em_curso',
    iniciado_por BIGINT,
    iniciado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    encerrado_por BIGINT,
    encerrado_em TIMESTAMPTZ,
    justificacao_reabertura TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_period_closings_period FOREIGN KEY (fiscal_period_id) REFERENCES fiscal_periods(id),
    CONSTRAINT chk_period_closings_status CHECK (status IN ('em_curso','verificado','encerrado','reaberto'))
);

CREATE INDEX IF NOT EXISTS idx_period_closings_tenant ON period_closings (tenant_id, fiscal_period_id);
CREATE INDEX IF NOT EXISTS idx_period_closings_status ON period_closings (tenant_id, status);

CREATE TABLE IF NOT EXISTS period_closing_checks (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    period_closing_id BIGINT NOT NULL,
    verificacao VARCHAR(100) NOT NULL,
    passou BOOLEAN NOT NULL,
    detalhe TEXT,
    verificado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_period_closing_checks_closing FOREIGN KEY (period_closing_id) REFERENCES period_closings(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_period_closing_checks_closing ON period_closing_checks (period_closing_id);
