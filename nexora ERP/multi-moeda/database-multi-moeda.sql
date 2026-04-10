-- Modulo Multi-Moeda para PostgreSQL
-- Complementa as tabelas currencies e exchange_rates do modulo sistema-configuracao
-- Foca em historico de conversoes e politicas de taxa por documento

CREATE TABLE IF NOT EXISTS exchange_rate_policies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('taxa_do_dia', 'taxa_fixa', 'taxa_media_mensal')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_exchange_rate_policies UNIQUE (tenant_id, nome)
);

CREATE TABLE IF NOT EXISTS currency_conversions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    from_currency VARCHAR(10) NOT NULL,
    to_currency VARCHAR(10) NOT NULL,
    rate NUMERIC(18,6) NOT NULL CHECK (rate > 0),
    amount_original NUMERIC(18,2) NOT NULL,
    amount_converted NUMERIC(18,2) NOT NULL,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    converted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS document_currencies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    documento_tipo VARCHAR(50) NOT NULL,
    documento_id BIGINT NOT NULL,
    moeda_documento VARCHAR(10) NOT NULL,
    moeda_base VARCHAR(10) NOT NULL,
    taxa_cambio NUMERIC(18,6) NOT NULL,
    total_moeda_documento NUMERIC(18,2) NOT NULL,
    total_moeda_base NUMERIC(18,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_document_currencies UNIQUE (tenant_id, documento_tipo, documento_id)
);

CREATE TABLE IF NOT EXISTS currency_rounding_rules (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    currency_codigo VARCHAR(10) NOT NULL,
    casas_decimais INTEGER NOT NULL DEFAULT 2,
    metodo VARCHAR(20) NOT NULL DEFAULT 'half_up' CHECK (metodo IN ('half_up', 'half_down', 'ceiling', 'floor')),
    CONSTRAINT uq_currency_rounding UNIQUE (tenant_id, currency_codigo)
);

CREATE INDEX IF NOT EXISTS idx_currency_conversions_tenant_id ON currency_conversions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_currency_conversions_referencia ON currency_conversions (referencia_tipo, referencia_id);
CREATE INDEX IF NOT EXISTS idx_document_currencies_doc ON document_currencies (documento_tipo, documento_id);
