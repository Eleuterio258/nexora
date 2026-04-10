-- Modulo de Sistema e Configuracao para PostgreSQL

CREATE TABLE IF NOT EXISTS settings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT,
    chave VARCHAR(120) NOT NULL,
    valor TEXT,
    escopo VARCHAR(30) NOT NULL DEFAULT 'global' CHECK (escopo IN ('global', 'tenant', 'user'))
);

CREATE TABLE IF NOT EXISTS currencies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nome VARCHAR(80) NOT NULL,
    simbolo VARCHAR(10),
    ativa BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_currencies UNIQUE (codigo)
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_currency_id BIGINT NOT NULL,
    to_currency_id BIGINT NOT NULL,
    rate NUMERIC(18,6) NOT NULL,
    rate_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS countries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    CONSTRAINT uq_countries UNIQUE (codigo)
);

CREATE TABLE IF NOT EXISTS cities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_id BIGINT,
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS languages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nome VARCHAR(80) NOT NULL,
    CONSTRAINT uq_languages UNIQUE (codigo)
);

CREATE TABLE IF NOT EXISTS email_templates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT,
    codigo VARCHAR(50) NOT NULL,
    assunto VARCHAR(150) NOT NULL,
    corpo TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sms_templates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT,
    codigo VARCHAR(50) NOT NULL,
    corpo TEXT NOT NULL
);

-- Nota: notificacoes de utilizador sao geridas pelo modulo utilizadores (tabela user_notifications).

CREATE TABLE IF NOT EXISTS system_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT,
    nivel VARCHAR(20) NOT NULL,
    modulo VARCHAR(80),
    mensagem TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS integrations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    configuracao JSONB,
    ativa BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS api_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT,
    metodo VARCHAR(10) NOT NULL,
    rota VARCHAR(255) NOT NULL,
    status_code INTEGER,
    duracao_ms INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
