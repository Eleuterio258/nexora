-- Modulo de Impostos Avancados para PostgreSQL
-- Complementa as tabelas tax_groups, taxes, tax_rules do modulo contabilidade

CREATE TABLE IF NOT EXISTS tax_regimes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_tax_regimes UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS tax_exemptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tax_id BIGINT NOT NULL,
    entity_type VARCHAR(30) NOT NULL CHECK (entity_type IN ('customer', 'supplier', 'product', 'product_category')),
    entity_id BIGINT NOT NULL,
    motivo VARCHAR(255),
    numero_isencao VARCHAR(60),
    validade DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS withholding_taxes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    taxa NUMERIC(8,4) NOT NULL CHECK (taxa >= 0),
    aplica_em VARCHAR(30) NOT NULL CHECK (aplica_em IN ('pagamento', 'fatura')),
    tipo_entidade VARCHAR(30) CHECK (tipo_entidade IN ('pessoa_singular', 'pessoa_colectiva', 'todos')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_withholding_taxes UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS withholding_tax_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    withholding_tax_id BIGINT NOT NULL,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    base_imponivel NUMERIC(18,2) NOT NULL,
    taxa_aplicada NUMERIC(8,4) NOT NULL,
    valor_retido NUMERIC(18,2) NOT NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_withholding_transactions_wt FOREIGN KEY (withholding_tax_id) REFERENCES withholding_taxes(id)
);

CREATE TABLE IF NOT EXISTS tax_returns (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fiscal_period_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('iva', 'irps', 'irpc', 'retencoes')),
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'submetida', 'paga', 'cancelada')),
    total_base NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_imposto NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_credito NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_a_pagar NUMERIC(18,2) NOT NULL DEFAULT 0,
    data_submissao TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tax_returns UNIQUE (tenant_id, fiscal_period_id, tipo)
);

CREATE TABLE IF NOT EXISTS tax_return_lines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tax_return_id BIGINT NOT NULL,
    tax_id BIGINT,
    descricao VARCHAR(150) NOT NULL,
    base_imponivel NUMERIC(18,2) NOT NULL DEFAULT 0,
    taxa NUMERIC(8,4) NOT NULL DEFAULT 0,
    valor_imposto NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_tax_return_lines_return FOREIGN KEY (tax_return_id) REFERENCES tax_returns(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tax_certificates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    entity_type VARCHAR(30) NOT NULL CHECK (entity_type IN ('customer', 'supplier', 'employee')),
    entity_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('isencao_iva', 'bom_contribuinte', 'retencao_na_fonte')),
    numero VARCHAR(60),
    emitido_em DATE,
    validade DATE,
    ficheiro_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tax_exemptions_tenant_id ON tax_exemptions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_exemptions_entity ON tax_exemptions (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_withholding_transactions_tenant_id ON withholding_tax_transactions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_returns_tenant_period ON tax_returns (tenant_id, fiscal_period_id);
CREATE INDEX IF NOT EXISTS idx_tax_certificates_entity ON tax_certificates (entity_type, entity_id);
