CREATE TABLE IF NOT EXISTS tax_regimes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_tax_regimes UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS taxes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    taxa NUMERIC(8,4) NOT NULL DEFAULT 0 CHECK (taxa >= 0),
    tipo VARCHAR(20) NOT NULL DEFAULT 'iva' CHECK (tipo IN ('iva','isento','zero','outro')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_taxes UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS tax_exemptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tax_id BIGINT NOT NULL,
    entity_type VARCHAR(30) NOT NULL CHECK (entity_type IN ('customer','supplier','product','product_category')),
    entity_id BIGINT NOT NULL,
    motivo VARCHAR(255),
    numero_isencao VARCHAR(60),
    validade DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tax_exemptions_tax FOREIGN KEY (tax_id) REFERENCES taxes(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS withholding_taxes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    taxa NUMERIC(8,4) NOT NULL CHECK (taxa >= 0),
    aplica_em VARCHAR(30) NOT NULL CHECK (aplica_em IN ('pagamento','fatura')),
    tipo_entidade VARCHAR(30) CHECK (tipo_entidade IN ('pessoa_singular','pessoa_colectiva','todos')),
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
    CONSTRAINT fk_wtt_wt FOREIGN KEY (withholding_tax_id) REFERENCES withholding_taxes(id)
);
CREATE TABLE IF NOT EXISTS tax_returns (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    periodo VARCHAR(20) NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('iva','irps','irpc','retencoes')),
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','submetida','paga','cancelada')),
    total_base NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_imposto NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_credito NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_a_pagar NUMERIC(18,2) NOT NULL DEFAULT 0,
    data_submissao TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tax_returns UNIQUE (tenant_id, periodo, tipo)
);
CREATE INDEX IF NOT EXISTS idx_tax_regimes_tenant ON tax_regimes (tenant_id);
CREATE INDEX IF NOT EXISTS idx_taxes_tenant ON taxes (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_exemptions_tenant ON tax_exemptions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_exemptions_entity ON tax_exemptions (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_wtt_tenant ON withholding_tax_transactions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_returns_tenant ON tax_returns (tenant_id);
