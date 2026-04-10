CREATE TABLE IF NOT EXISTS currencies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),
    decimals INTEGER NOT NULL DEFAULT 2 CHECK (decimals BETWEEN 0 AND 6),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_currencies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    currency_id BIGINT NOT NULL,
    is_base BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_currencies UNIQUE (tenant_id, currency_id),
    CONSTRAINT fk_tenant_currencies_currency FOREIGN KEY (currency_id) REFERENCES currencies(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    base_currency_id BIGINT NOT NULL,
    quote_currency_id BIGINT NOT NULL,
    rate NUMERIC(18,6) NOT NULL CHECK (rate > 0),
    source VARCHAR(50) NOT NULL DEFAULT 'manual',
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_official BOOLEAN NOT NULL DEFAULT FALSE,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_exchange_rates UNIQUE (tenant_id, base_currency_id, quote_currency_id, effective_date, source),
    CONSTRAINT fk_exchange_rates_base FOREIGN KEY (base_currency_id) REFERENCES currencies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_exchange_rates_quote FOREIGN KEY (quote_currency_id) REFERENCES currencies(id) ON DELETE RESTRICT,
    CONSTRAINT chk_exchange_rate_pair CHECK (base_currency_id <> quote_currency_id)
);

INSERT INTO currencies (code, name, symbol, decimals)
VALUES
    ('MZN', 'Metical Mocambicano', 'MT', 2),
    ('USD', 'US Dollar', '$', 2),
    ('ZAR', 'South African Rand', 'R', 2),
    ('EUR', 'Euro', 'EUR', 2)
ON CONFLICT (code) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_tenant_currencies_tenant ON tenant_currencies (tenant_id, is_base);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_tenant_date ON exchange_rates (tenant_id, effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_pair ON exchange_rates (tenant_id, base_currency_id, quote_currency_id, effective_date DESC);
