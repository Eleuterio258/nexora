CREATE SCHEMA IF NOT EXISTS clientes;
SET search_path TO clientes, public;

-- Modulo de Gestao de Clientes para PostgreSQL

CREATE TABLE IF NOT EXISTS customer_groups (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_groups UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    customer_group_id BIGINT,
    codigo VARCHAR(50),
    nome VARCHAR(150) NOT NULL,
    nuit VARCHAR(30),
    telefone VARCHAR(30),
    email VARCHAR(120),
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (estado IN ('ativo', 'inativo', 'bloqueado')),
    observacao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo),
    CONSTRAINT uq_customers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit),
    CONSTRAINT fk_customers_group FOREIGN KEY (customer_group_id) REFERENCES customer_groups(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS customer_contacts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    cargo VARCHAR(100),
    telefone VARCHAR(30),
    email VARCHAR(120),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_contacts_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'principal' CHECK (tipo IN ('principal', 'entrega', 'cobranca', 'fiscal')),
    endereco VARCHAR(255) NOT NULL,
    cidade VARCHAR(100),
    provincia VARCHAR(100),
    pais VARCHAR(100) NOT NULL DEFAULT 'Mocambique',
    codigo_postal VARCHAR(30),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_addresses_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('contrato', 'nuit', 'bi', 'comprovativo', 'outro')),
    numero VARCHAR(100),
    ficheiro_url TEXT,
    emitido_em DATE,
    expira_em DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_documents_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_credit_limits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    limite_credito NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (limite_credito >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    inicio_em DATE,
    fim_em DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_credit_limits_customer UNIQUE (customer_id),
    CONSTRAINT fk_customer_credit_limits_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_balances (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    saldo_atual NUMERIC(18,2) NOT NULL DEFAULT 0,
    saldo_vencido NUMERIC(18,2) NOT NULL DEFAULT 0,
    credito_disponivel NUMERIC(18,2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_balances_customer UNIQUE (customer_id),
    CONSTRAINT fk_customer_balances_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    documento_id BIGINT,
    metodo VARCHAR(30) NOT NULL CHECK (metodo IN ('dinheiro', 'transferencia', 'mpesa', 'emola', 'cartao')),
    referencia VARCHAR(100),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    pago_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacao TEXT,
    CONSTRAINT fk_customer_payments_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    nota TEXT NOT NULL,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_notes_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    evento VARCHAR(100) NOT NULL,
    descricao TEXT,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_history_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_tags (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    cor VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_tags UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS customer_tag_links (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    customer_tag_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_tag_links UNIQUE (customer_id, customer_tag_id),
    CONSTRAINT fk_customer_tag_links_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    CONSTRAINT fk_customer_tag_links_tag FOREIGN KEY (customer_tag_id) REFERENCES customer_tags(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer_discounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('percentual', 'valor_fixo')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    motivo VARCHAR(150),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    inicio_em DATE,
    fim_em DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_discounts_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_customer_groups_tenant_id ON customer_groups (tenant_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_id ON customers (tenant_id);
CREATE INDEX IF NOT EXISTS idx_customers_group_id ON customers (customer_group_id);
CREATE INDEX IF NOT EXISTS idx_customer_contacts_customer_id ON customer_contacts (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_id ON customer_addresses (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_documents_customer_id ON customer_documents (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_payments_customer_id ON customer_payments (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_notes_customer_id ON customer_notes (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_history_customer_id ON customer_history (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_links_customer_id ON customer_tag_links (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_discounts_customer_id ON customer_discounts (customer_id);
