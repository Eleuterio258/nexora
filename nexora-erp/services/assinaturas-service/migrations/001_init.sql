CREATE TABLE IF NOT EXISTS subscription_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    billing_period VARCHAR(20) NOT NULL DEFAULT 'mensal' CHECK (billing_period IN ('mensal','trimestral','anual')),
    preco NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    limites JSONB,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_subscription_plans UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    company_id BIGINT,
    plan_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    starts_at DATE NOT NULL,
    ends_at DATE,
    next_billing_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','activa','suspensa','cancelada','expirada')),
    unit_price NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_subscriptions UNIQUE (tenant_id, numero),
    CONSTRAINT fk_subscriptions_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS subscription_invoices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    subscription_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    due_date DATE NOT NULL,
    valor_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'emitida' CHECK (status IN ('emitida','paga','cancelada','vencida')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_subscription_invoices UNIQUE (tenant_id, numero),
    CONSTRAINT fk_subscription_invoices_subscription FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS subscription_usage (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    subscription_id BIGINT NOT NULL,
    recurso VARCHAR(100) NOT NULL,
    quantidade NUMERIC(18,2) NOT NULL DEFAULT 0,
    periodo DATE NOT NULL DEFAULT CURRENT_DATE,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscription_usage_subscription FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_subscription_plans_tenant ON subscription_plans (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_status ON subscriptions (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_subscription_invoices_tenant_status ON subscription_invoices (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_tenant_periodo ON subscription_usage (tenant_id, periodo);
