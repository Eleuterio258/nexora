CREATE TABLE IF NOT EXISTS accounting_periods (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER CHECK (mes BETWEEN 1 AND 12),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto','fechado')),
    fechado_em TIMESTAMPTZ,
    fechado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_accounting_periods UNIQUE (tenant_id, ano, mes)
);

CREATE TABLE IF NOT EXISTS chart_of_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('ativo','passivo','capital','rendimento','gasto')),
    natureza VARCHAR(20) NOT NULL CHECK (natureza IN ('devedora','credora')),
    aceita_movimento BOOLEAN NOT NULL DEFAULT TRUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_chart_of_accounts UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_chart_parent FOREIGN KEY (parent_id) REFERENCES chart_of_accounts(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS accounting_journals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('geral','vendas','compras','tesouraria','folha','ajuste')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_accounting_journals UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS journal_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    accounting_period_id BIGINT NOT NULL,
    accounting_journal_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    entry_date DATE NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','publicado','anulado')),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    total_debito NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_credito NUMERIC(18,2) NOT NULL DEFAULT 0,
    criado_por BIGINT,
    publicado_por BIGINT,
    publicado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_journal_entries UNIQUE (tenant_id, numero),
    CONSTRAINT fk_journal_entries_period FOREIGN KEY (accounting_period_id) REFERENCES accounting_periods(id) ON DELETE RESTRICT,
    CONSTRAINT fk_journal_entries_journal FOREIGN KEY (accounting_journal_id) REFERENCES accounting_journals(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS journal_entry_lines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    journal_entry_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,
    descricao VARCHAR(255),
    debit NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
    credit NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
    reference_type VARCHAR(50),
    reference_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_journal_entry_lines_entry FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE,
    CONSTRAINT fk_journal_entry_lines_account FOREIGN KEY (account_id) REFERENCES chart_of_accounts(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_accounting_periods_tenant ON accounting_periods (tenant_id, ano, mes);
CREATE INDEX IF NOT EXISTS idx_chart_of_accounts_tenant ON chart_of_accounts (tenant_id, codigo);
CREATE INDEX IF NOT EXISTS idx_accounting_journals_tenant ON accounting_journals (tenant_id, codigo);
CREATE INDEX IF NOT EXISTS idx_journal_entries_tenant_date ON journal_entries (tenant_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_entries_status ON journal_entries (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_entry ON journal_entry_lines (journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_account ON journal_entry_lines (account_id);
