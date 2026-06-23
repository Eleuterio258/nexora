SET search_path TO contabilidade, public;

CREATE TABLE IF NOT EXISTS fixed_assets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    chart_account_id BIGINT NOT NULL,
    depreciation_account_id BIGINT NOT NULL,
    accumulated_depreciation_account_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    data_aquisicao DATE NOT NULL,
    valor_aquisicao NUMERIC(18,2) NOT NULL,
    valor_residual NUMERIC(18,2) NOT NULL DEFAULT 0,
    vida_util_meses INTEGER NOT NULL,
    metodo VARCHAR(20) NOT NULL DEFAULT 'linha_recta',
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo',
    data_alienacao DATE,
    valor_alienacao NUMERIC(18,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fixed_assets_account FOREIGN KEY (chart_account_id) REFERENCES chart_of_accounts(id),
    CONSTRAINT fk_fixed_assets_depr_account FOREIGN KEY (depreciation_account_id) REFERENCES chart_of_accounts(id),
    CONSTRAINT fk_fixed_assets_accum_account FOREIGN KEY (accumulated_depreciation_account_id) REFERENCES chart_of_accounts(id),
    CONSTRAINT uq_fixed_assets_codigo UNIQUE (tenant_id, codigo),
    CONSTRAINT chk_fixed_assets_metodo CHECK (metodo IN ('linha_recta')),
    CONSTRAINT chk_fixed_assets_estado CHECK (estado IN ('ativo', 'alienado')),
    CONSTRAINT chk_fixed_assets_valor_aquisicao CHECK (valor_aquisicao > 0),
    CONSTRAINT chk_fixed_assets_valor_residual CHECK (valor_residual >= 0),
    CONSTRAINT chk_fixed_assets_vida_util CHECK (vida_util_meses > 0)
);

CREATE INDEX IF NOT EXISTS idx_fixed_assets_tenant ON fixed_assets (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_fixed_assets_account ON fixed_assets (chart_account_id);

CREATE TABLE IF NOT EXISTS depreciation_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fixed_asset_id BIGINT NOT NULL,
    fiscal_period_id BIGINT NOT NULL,
    numero_parcela INTEGER NOT NULL,
    valor_amortizacao NUMERIC(18,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente',
    journal_entry_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_depreciation_entries_asset FOREIGN KEY (fixed_asset_id) REFERENCES fixed_assets(id),
    CONSTRAINT fk_depreciation_entries_period FOREIGN KEY (fiscal_period_id) REFERENCES fiscal_periods(id),
    CONSTRAINT fk_depreciation_entries_journal FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id),
    CONSTRAINT uq_depreciation_entries_asset_period UNIQUE (fixed_asset_id, fiscal_period_id),
    CONSTRAINT chk_depreciation_entries_status CHECK (status IN ('pendente', 'processado', 'cancelado')),
    CONSTRAINT chk_depreciation_entries_valor CHECK (valor_amortizacao >= 0)
);

CREATE INDEX IF NOT EXISTS idx_depreciation_entries_tenant ON depreciation_entries (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_depreciation_entries_asset ON depreciation_entries (fixed_asset_id);
CREATE INDEX IF NOT EXISTS idx_depreciation_entries_period ON depreciation_entries (fiscal_period_id);
CREATE INDEX IF NOT EXISTS idx_depreciation_entries_journal ON depreciation_entries (journal_entry_id);
