CREATE TABLE IF NOT EXISTS cost_centers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'centro' CHECK (tipo IN ('centro','departamento','projecto')),
    gestor_user_id BIGINT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cost_centers UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_cost_centers_parent FOREIGN KEY (parent_id) REFERENCES cost_centers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS cost_center_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cost_center_id BIGINT NOT NULL,
    source_service VARCHAR(100) NOT NULL,
    source_type VARCHAR(100) NOT NULL,
    source_id BIGINT NOT NULL,
    source_line_id BIGINT,
    descricao VARCHAR(255),
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    allocation_percent NUMERIC(8,4) NOT NULL DEFAULT 100 CHECK (allocation_percent > 0 AND allocation_percent <= 100),
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cost_center_allocations_center FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS cost_center_budgets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cost_center_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER CHECK (mes BETWEEN 1 AND 12),
    valor_orcamentado NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cost_center_budgets UNIQUE (tenant_id, cost_center_id, ano, mes),
    CONSTRAINT fk_cost_center_budgets_center FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_cost_centers_tenant ON cost_centers (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_cost_center_allocations_tenant ON cost_center_allocations (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cost_center_allocations_source ON cost_center_allocations (tenant_id, source_service, source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_cost_center_budgets_tenant ON cost_center_budgets (tenant_id, ano, mes);
