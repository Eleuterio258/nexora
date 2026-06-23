-- Modulo de Centros de Custo para PostgreSQL

CREATE TABLE IF NOT EXISTS cost_centers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    parent_id BIGINT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cost_centers UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_cost_centers_parent FOREIGN KEY (parent_id) REFERENCES cost_centers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS cost_center_budgets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cost_center_id BIGINT NOT NULL,
    fiscal_period_id BIGINT NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('receita', 'despesa')),
    valor_orcamentado NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (valor_orcamentado >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cost_center_budgets UNIQUE (cost_center_id, fiscal_period_id, tipo),
    CONSTRAINT fk_cost_center_budgets_cc FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cost_center_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cost_center_id BIGINT NOT NULL,
    journal_entry_line_id BIGINT,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    valor NUMERIC(18,2) NOT NULL,
    percentagem NUMERIC(5,2) CHECK (percentagem BETWEEN 0 AND 100),
    data_alocacao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cost_center_allocations_cc FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cost_center_movements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cost_center_id BIGINT NOT NULL,
    fiscal_period_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('receita', 'despesa')),
    valor NUMERIC(18,2) NOT NULL,
    descricao TEXT,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    data_movimento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cost_center_movements_cc FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_cost_centers_tenant_id ON cost_centers (tenant_id);
CREATE INDEX IF NOT EXISTS idx_cost_centers_parent_id ON cost_centers (parent_id);
CREATE INDEX IF NOT EXISTS idx_cost_center_budgets_cc_id ON cost_center_budgets (cost_center_id);
CREATE INDEX IF NOT EXISTS idx_cost_center_allocations_cc_id ON cost_center_allocations (cost_center_id);
CREATE INDEX IF NOT EXISTS idx_cost_center_movements_cc_id ON cost_center_movements (cost_center_id);
