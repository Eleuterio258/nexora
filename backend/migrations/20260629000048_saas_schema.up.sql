CREATE SCHEMA IF NOT EXISTS saas;
SET search_path TO saas, public;

-- Planos globais disponíveis para todos os tenants
CREATE TABLE IF NOT EXISTS plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    preco_mensal NUMERIC(18,2) NOT NULL DEFAULT 0,
    preco_anual NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    limites JSONB NOT NULL DEFAULT '{}',
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_plans_codigo UNIQUE (codigo)
);

-- Tenants (entidades/empresas isoladas na plataforma)
CREATE TABLE IF NOT EXISTS tenants (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    company_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo', 'suspenso', 'inativo')),
    dominio VARCHAR(255),
    plano_id BIGINT,
    limite_utilizadores INTEGER,
    limite_armazenamento_gb INTEGER,
    validade_plano DATE,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenants_codigo UNIQUE (codigo),
    CONSTRAINT fk_tenants_plano FOREIGN KEY (plano_id) REFERENCES plans(id) ON DELETE SET NULL
);

-- Módulos/features ativas por tenant
CREATE TABLE IF NOT EXISTS tenant_modules (
    tenant_id BIGINT NOT NULL,
    modulo VARCHAR(50) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tenant_id, modulo),
    CONSTRAINT fk_tenant_modules_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Subscrições dos tenants
CREATE TABLE IF NOT EXISTS tenant_subscriptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    plano_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    starts_at DATE NOT NULL,
    ends_at DATE,
    next_billing_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'activa' CHECK (status IN ('pendente', 'activa', 'suspensa', 'cancelada', 'expirada')),
    unit_price NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tenant_subscriptions_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tenant_subscriptions_plano FOREIGN KEY (plano_id) REFERENCES plans(id) ON DELETE RESTRICT
);

-- Configurações globais da plataforma (escopo global)
CREATE TABLE IF NOT EXISTS global_settings (
    chave VARCHAR(100) NOT NULL PRIMARY KEY,
    valor TEXT,
    descricao TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_tenants_company_id ON tenants (company_id);
CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants (status);
CREATE INDEX IF NOT EXISTS idx_tenants_plano_id ON tenants (plano_id);
CREATE INDEX IF NOT EXISTS idx_tenant_modules_tenant_id ON tenant_modules (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_tenant_id ON tenant_subscriptions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_subscriptions_status ON tenant_subscriptions (status);

-- Dados iniciais: plano padrão
INSERT INTO plans (codigo, nome, descricao, preco_mensal, preco_anual, moeda, limites, ativo)
VALUES (
    'basico',
    'Básico',
    'Plano básico com módulos essenciais',
    0,
    0,
    'MZN',
    '{"utilizadores": 10, "armazenamento_gb": 5, "filiais": 1}'::jsonb,
    TRUE
)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO plans (codigo, nome, descricao, preco_mensal, preco_anual, moeda, limites, ativo)
VALUES (
    'profissional',
    'Profissional',
    'Plano profissional com todos os módulos operacionais',
    5000,
    50000,
    'MZN',
    '{"utilizadores": 50, "armazenamento_gb": 50, "filiais": 5}'::jsonb,
    TRUE
)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO plans (codigo, nome, descricao, preco_mensal, preco_anual, moeda, limites, ativo)
VALUES (
    'empresarial',
    'Empresarial',
    'Plano empresarial sem limites',
    15000,
    150000,
    'MZN',
    '{"utilizadores": null, "armazenamento_gb": null, "filiais": null}'::jsonb,
    TRUE
)
ON CONFLICT (codigo) DO NOTHING;

-- Configurações globais iniciais
INSERT INTO global_settings (chave, valor, descricao)
VALUES
    ('plataforma.nome', 'Nexora ERP', 'Nome da plataforma'),
    ('plataforma.idioma_padrao', 'pt', 'Idioma padrão'),
    ('plataforma.moeda_padrao', 'MZN', 'Moeda padrão'),
    ('plataforma.timezone_padrao', 'Africa/Maputo', 'Timezone padrão'),
    ('plataforma.manutencao', 'false', 'Modo de manutenção'),
    ('smtp.host', '', 'Servidor SMTP'),
    ('smtp.port', '587', 'Porta SMTP'),
    ('smtp.user', '', 'Utilizador SMTP'),
    ('sms.gateway', '', 'Gateway SMS')
ON CONFLICT (chave) DO NOTHING;
