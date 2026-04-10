-- Schema do modulo de Assinaturas SaaS / Licencas

-- Gateways de pagamento disponiveis (M-Pesa, E-Mola, Stripe, etc.)
CREATE TABLE IF NOT EXISTS payment_gateways (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    codigo      VARCHAR(30) NOT NULL,
    nome        VARCHAR(80) NOT NULL,
    tipo        VARCHAR(30) NOT NULL CHECK (tipo IN ('mpesa', 'emola', 'stripe', 'paypal', 'transferencia', 'outro')),
    configuracao JSONB,
    ativo       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payment_gateways UNIQUE (tenant_id, codigo)
);

-- Planos SaaS com limites operacionais
CREATE TABLE IF NOT EXISTS subscription_plans (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id             BIGINT NOT NULL,
    codigo                VARCHAR(50) NOT NULL,
    nome                  VARCHAR(120) NOT NULL,
    descricao             TEXT,
    preco                 NUMERIC(18,2) NOT NULL CHECK (preco >= 0),
    moeda                 VARCHAR(10) NOT NULL DEFAULT 'MZN',
    ciclo                 VARCHAR(20) NOT NULL CHECK (ciclo IN ('mensal', 'trimestral', 'semestral', 'anual')),
    trial_dias            INTEGER NOT NULL DEFAULT 0 CHECK (trial_dias >= 0),
    max_utilizadores      INTEGER,
    max_filiais           INTEGER,
    max_produtos          INTEGER,
    max_documentos_mes    INTEGER,
    modulos               JSONB,
    ativo                 BOOLEAN NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_subscription_plans UNIQUE (tenant_id, codigo)
);

-- Funcionalidades e limites descritivos por plano (para pagina de comparacao)
CREATE TABLE IF NOT EXISTS subscription_plan_features (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plan_id     BIGINT NOT NULL,
    codigo      VARCHAR(50) NOT NULL,
    descricao   VARCHAR(200) NOT NULL,
    incluido    BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_plan_features_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE CASCADE
);

-- Assinaturas das empresas (tenants)
CREATE TABLE IF NOT EXISTS subscriptions (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id           BIGINT NOT NULL,
    customer_id         BIGINT NOT NULL,
    plan_id             BIGINT NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'trial'
                            CHECK (status IN ('trial', 'activa', 'pausada', 'suspensa', 'cancelada', 'expirada')),
    inicio_em           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    trial_fim_em        TIMESTAMPTZ,
    proxima_fatura_em   TIMESTAMPTZ,
    cancelamento_em     TIMESTAMPTZ,
    dias_tolerancia     INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscriptions_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id)
);

-- Ciclos de faturacao gerados automaticamente
CREATE TABLE IF NOT EXISTS subscription_billing_cycles (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subscription_id BIGINT NOT NULL,
    periodo_inicio  TIMESTAMPTZ NOT NULL,
    periodo_fim     TIMESTAMPTZ NOT NULL,
    valor           NUMERIC(18,2) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente'
                        CHECK (status IN ('pendente', 'faturado', 'pago', 'cancelado')),
    invoice_id      BIGINT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_billing_cycles_subscription FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
);

-- Pagamentos efectuados por assinatura
CREATE TABLE IF NOT EXISTS subscription_payments (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id           BIGINT NOT NULL,
    subscription_id     BIGINT NOT NULL,
    billing_cycle_id    BIGINT,
    payment_gateway_id  BIGINT,
    valor               NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    moeda               VARCHAR(10) NOT NULL DEFAULT 'MZN',
    referencia_gateway  VARCHAR(200),
    status              VARCHAR(20) NOT NULL DEFAULT 'pendente'
                            CHECK (status IN ('pendente', 'confirmado', 'falhado', 'estornado')),
    tentativas          INTEGER NOT NULL DEFAULT 0,
    pago_em             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sub_payments_subscription FOREIGN KEY (subscription_id) REFERENCES subscriptions(id),
    CONSTRAINT fk_sub_payments_cycle FOREIGN KEY (billing_cycle_id) REFERENCES subscription_billing_cycles(id),
    CONSTRAINT fk_sub_payments_gateway FOREIGN KEY (payment_gateway_id) REFERENCES payment_gateways(id)
);

-- Registo de uso por metrica (para planos baseados em consumo)
CREATE TABLE IF NOT EXISTS subscription_usage (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subscription_id BIGINT NOT NULL,
    metrica         VARCHAR(80) NOT NULL,
    quantidade      NUMERIC(18,4) NOT NULL DEFAULT 0,
    periodo_inicio  TIMESTAMPTZ NOT NULL,
    periodo_fim     TIMESTAMPTZ NOT NULL,
    registado_em    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscription_usage_sub FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
);

-- Cancelamentos com efectividade futura
CREATE TABLE IF NOT EXISTS subscription_cancellations (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subscription_id BIGINT NOT NULL,
    motivo          VARCHAR(255),
    cancelado_por   BIGINT,
    cancelado_em    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    efectivo_em     TIMESTAMPTZ NOT NULL,
    CONSTRAINT uq_subscription_cancellations UNIQUE (subscription_id),
    CONSTRAINT fk_sub_cancellations_sub FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
);

-- Pausas manuais por periodo definido
CREATE TABLE IF NOT EXISTS subscription_pauses (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subscription_id BIGINT NOT NULL,
    pausado_em      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retoma_em       TIMESTAMPTZ,
    motivo          VARCHAR(255),
    CONSTRAINT fk_sub_pauses_sub FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
);

-- Log de eventos da licenca (audit trail completo)
CREATE TABLE IF NOT EXISTS subscription_events (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    subscription_id BIGINT NOT NULL,
    tipo            VARCHAR(50) NOT NULL
                        CHECK (tipo IN (
                            'criacao', 'trial_inicio', 'trial_fim',
                            'upgrade', 'downgrade',
                            'renovacao', 'pagamento_confirmado', 'falha_pagamento',
                            'suspensao_automatica', 'reativacao',
                            'pausa', 'retoma',
                            'cancelamento', 'cancelamento_revertido',
                            'limite_atingido'
                        )),
    descricao       TEXT,
    dados           JSONB,
    registado_em    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registado_por   BIGINT,
    CONSTRAINT fk_sub_events_subscription FOREIGN KEY (subscription_id) REFERENCES subscriptions(id)
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_payment_gateways_tenant_id ON payment_gateways (tenant_id);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_tenant_id ON subscription_plans (tenant_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_id ON subscriptions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer_id ON subscriptions (customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions (status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_proxima_fatura ON subscriptions (proxima_fatura_em) WHERE status = 'activa';
CREATE INDEX IF NOT EXISTS idx_billing_cycles_subscription_id ON subscription_billing_cycles (subscription_id);
CREATE INDEX IF NOT EXISTS idx_billing_cycles_status ON subscription_billing_cycles (status);
CREATE INDEX IF NOT EXISTS idx_sub_payments_subscription_id ON subscription_payments (subscription_id);
CREATE INDEX IF NOT EXISTS idx_sub_payments_status ON subscription_payments (status);
CREATE INDEX IF NOT EXISTS idx_sub_events_subscription_id ON subscription_events (subscription_id);
CREATE INDEX IF NOT EXISTS idx_sub_events_tipo ON subscription_events (tipo);
CREATE INDEX IF NOT EXISTS idx_sub_events_tenant_id ON subscription_events (tenant_id);
