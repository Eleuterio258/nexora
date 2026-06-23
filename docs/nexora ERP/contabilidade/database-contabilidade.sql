-- Modulo de Contabilidade para PostgreSQL

CREATE TABLE IF NOT EXISTS account_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    natureza VARCHAR(20) NOT NULL CHECK (natureza IN ('debito', 'credito')),
    CONSTRAINT uq_account_types UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS chart_of_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    account_type_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    aceita_lancamento BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_chart_of_accounts UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS fiscal_years (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'fechado')),
    CONSTRAINT uq_fiscal_years UNIQUE (tenant_id, ano)
);

CREATE TABLE IF NOT EXISTS fiscal_periods (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fiscal_year_id BIGINT NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'fechado')),
    CONSTRAINT uq_fiscal_periods UNIQUE (fiscal_year_id, codigo)
);

CREATE TABLE IF NOT EXISTS journal_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fiscal_period_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    entry_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    referencia VARCHAR(100),
    descricao TEXT,
    origem_tipo VARCHAR(50),
    origem_id BIGINT,
    CONSTRAINT uq_journal_entries UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS journal_entry_lines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    journal_entry_id BIGINT NOT NULL,
    chart_account_id BIGINT NOT NULL,
    debito NUMERIC(18,2) NOT NULL DEFAULT 0,
    credito NUMERIC(18,2) NOT NULL DEFAULT 0,
    descricao TEXT,
    CONSTRAINT fk_journal_entry_lines_entry FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tax_groups (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30),
    nome VARCHAR(120) NOT NULL
);

CREATE TABLE IF NOT EXISTS taxes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tax_group_id BIGINT,
    codigo VARCHAR(30),
    nome VARCHAR(120) NOT NULL,
    taxa NUMERIC(8,4) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS tax_rules (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tax_id BIGINT NOT NULL,
    regra VARCHAR(120) NOT NULL,
    valor VARCHAR(120)
);

CREATE TABLE IF NOT EXISTS tax_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tax_id BIGINT,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    base_imponivel NUMERIC(18,2) NOT NULL,
    tax_amount NUMERIC(18,2) NOT NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS trial_balance (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fiscal_period_id BIGINT,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dados JSONB
);

CREATE TABLE IF NOT EXISTS balance_sheet (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fiscal_period_id BIGINT,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dados JSONB
);

CREATE TABLE IF NOT EXISTS income_statement (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fiscal_period_id BIGINT,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dados JSONB
);

-- Contabilidade Completa: Amortizacoes, Orcamentos Contabilisticos, Encerramento de Periodo

CREATE TABLE IF NOT EXISTS fixed_assets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    chart_account_id BIGINT,
    data_aquisicao DATE NOT NULL,
    valor_aquisicao NUMERIC(18,2) NOT NULL CHECK (valor_aquisicao > 0),
    valor_residual NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (valor_residual >= 0),
    vida_util_meses INTEGER NOT NULL CHECK (vida_util_meses > 0),
    metodo_amortizacao VARCHAR(20) NOT NULL DEFAULT 'linear' CHECK (metodo_amortizacao IN ('linear', 'degressive', 'unidades_producao')),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'totalmente_amortizado', 'alienado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fixed_assets UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS depreciation_schedules (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fixed_asset_id BIGINT NOT NULL,
    fiscal_period_id BIGINT NOT NULL,
    valor_amortizacao NUMERIC(18,2) NOT NULL,
    valor_acumulado NUMERIC(18,2) NOT NULL,
    valor_contabilistico NUMERIC(18,2) NOT NULL,
    journal_entry_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'lancado', 'cancelado')),
    CONSTRAINT uq_depreciation_schedules UNIQUE (fixed_asset_id, fiscal_period_id),
    CONSTRAINT fk_depreciation_fixed_asset FOREIGN KEY (fixed_asset_id) REFERENCES fixed_assets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS budget_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fiscal_year_id BIGINT NOT NULL,
    chart_account_id BIGINT NOT NULL,
    valor_orcamentado NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_budget_accounts UNIQUE (tenant_id, fiscal_year_id, chart_account_id)
);

CREATE TABLE IF NOT EXISTS period_closings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fiscal_period_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'em_fecho', 'fechado')),
    verificacoes_ok BOOLEAN NOT NULL DEFAULT FALSE,
    encerrado_em TIMESTAMPTZ,
    encerrado_por BIGINT,
    observacoes TEXT,
    CONSTRAINT uq_period_closings UNIQUE (tenant_id, fiscal_period_id)
);

CREATE TABLE IF NOT EXISTS closing_checks (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    period_closing_id BIGINT NOT NULL,
    verificacao VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'ok', 'erro')),
    detalhe TEXT,
    verificado_em TIMESTAMPTZ,
    CONSTRAINT fk_closing_checks_closing FOREIGN KEY (period_closing_id) REFERENCES period_closings(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_fixed_assets_tenant_id ON fixed_assets (tenant_id);
CREATE INDEX IF NOT EXISTS idx_depreciation_schedules_asset_id ON depreciation_schedules (fixed_asset_id);
CREATE INDEX IF NOT EXISTS idx_budget_accounts_year_id ON budget_accounts (fiscal_year_id);
CREATE INDEX IF NOT EXISTS idx_period_closings_period_id ON period_closings (fiscal_period_id);
