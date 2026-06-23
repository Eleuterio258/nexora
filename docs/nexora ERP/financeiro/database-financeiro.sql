-- Modulo Financeiro para PostgreSQL
--
-- Responsabilidades: meios de pagamento, pagamentos/recebimentos,
-- contas a receber, contas a pagar, fluxo de caixa, orcamentos financeiros.
--
-- Dependencias:
--   tesouraria  — conta_bancaria_id, caixa_id (destino das transacoes)
--   contabilidade — alimenta com lancamentos via origem_tipo/origem_id

-- ============================================================
-- MEIOS DE PAGAMENTO
-- ============================================================

CREATE TABLE IF NOT EXISTS payment_methods (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'outro' CHECK (tipo IN ('numerario', 'transferencia', 'tpa', 'cheque', 'credito', 'debito', 'mpesa', 'emola', 'outro')),
    requer_referencia BOOLEAN NOT NULL DEFAULT FALSE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_payment_methods UNIQUE (tenant_id, codigo)
);

-- ============================================================
-- CATEGORIAS FINANCEIRAS
-- ============================================================

CREATE TABLE IF NOT EXISTS financial_categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT,
    codigo VARCHAR(30),
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('receita', 'despesa', 'transferencia')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_financial_categories_parent FOREIGN KEY (parent_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);

-- ============================================================
-- PAGAMENTOS E RECEBIMENTOS
-- ============================================================

CREATE TABLE IF NOT EXISTS payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    payment_method_id BIGINT,
    financial_category_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('recebimento', 'pagamento')),
    data_pagamento DATE NOT NULL,
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    descricao TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado' CHECK (status IN ('pendente', 'confirmado', 'cancelado')),
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payments UNIQUE (tenant_id, numero),
    CONSTRAINT fk_payments_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id) ON DELETE SET NULL,
    CONSTRAINT fk_payments_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS payment_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payment_id BIGINT NOT NULL,
    conta_bancaria_id BIGINT,
    caixa_id BIGINT,
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    referencia VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_transactions_payment FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
);

-- ============================================================
-- CONTAS A RECEBER
-- ============================================================

CREATE TABLE IF NOT EXISTS accounts_receivable (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    customer_id BIGINT NOT NULL,
    financial_category_id BIGINT,
    origem_tipo VARCHAR(50),
    origem_id BIGINT,
    descricao VARCHAR(255),
    valor_total NUMERIC(18,2) NOT NULL CHECK (valor_total > 0),
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pendente NUMERIC(18,2) GENERATED ALWAYS AS (valor_total - valor_pago) STORED,
    data_emissao DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'parcial', 'liquidada', 'cancelada', 'vencida')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_accounts_receivable UNIQUE (tenant_id, numero),
    CONSTRAINT fk_ar_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS accounts_receivable_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    accounts_receivable_id BIGINT NOT NULL,
    payment_id BIGINT NOT NULL,
    valor_imputado NUMERIC(18,2) NOT NULL CHECK (valor_imputado > 0),
    data_imputacao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ar_payments UNIQUE (accounts_receivable_id, payment_id),
    CONSTRAINT fk_ar_payments_ar FOREIGN KEY (accounts_receivable_id) REFERENCES accounts_receivable(id) ON DELETE CASCADE,
    CONSTRAINT fk_ar_payments_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
);

-- ============================================================
-- CONTAS A PAGAR
-- ============================================================

CREATE TABLE IF NOT EXISTS accounts_payable (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    supplier_id BIGINT,
    financial_category_id BIGINT,
    origem_tipo VARCHAR(50),
    origem_id BIGINT,
    descricao VARCHAR(255),
    valor_total NUMERIC(18,2) NOT NULL CHECK (valor_total > 0),
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pendente NUMERIC(18,2) GENERATED ALWAYS AS (valor_total - valor_pago) STORED,
    data_emissao DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'parcial', 'liquidada', 'cancelada', 'vencida')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_accounts_payable UNIQUE (tenant_id, numero),
    CONSTRAINT fk_ap_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS accounts_payable_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    accounts_payable_id BIGINT NOT NULL,
    payment_id BIGINT NOT NULL,
    valor_imputado NUMERIC(18,2) NOT NULL CHECK (valor_imputado > 0),
    data_imputacao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ap_payments UNIQUE (accounts_payable_id, payment_id),
    CONSTRAINT fk_ap_payments_ap FOREIGN KEY (accounts_payable_id) REFERENCES accounts_payable(id) ON DELETE CASCADE,
    CONSTRAINT fk_ap_payments_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
);

-- ============================================================
-- ORCAMENTOS FINANCEIROS
-- ============================================================

CREATE TABLE IF NOT EXISTS financial_budgets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    financial_category_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER CHECK (mes BETWEEN 1 AND 12),
    valor_orcamentado NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_financial_budgets UNIQUE (tenant_id, financial_category_id, ano, mes),
    CONSTRAINT fk_budgets_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE CASCADE
);

-- ============================================================
-- FLUXO DE CAIXA
-- ============================================================

CREATE TABLE IF NOT EXISTS cash_flow_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    financial_category_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('entrada', 'saida')),
    origem VARCHAR(30) NOT NULL CHECK (origem IN ('realizado', 'previsto')),
    data DATE NOT NULL,
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    descricao VARCHAR(255),
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cashflow_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);

-- ============================================================
-- RELATORIOS FINANCEIROS
-- ============================================================

CREATE TABLE IF NOT EXISTS financial_reports (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    referencia VARCHAR(50),
    gerado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    gerado_por BIGINT,
    dados JSONB
);

-- ============================================================
-- INDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_payment_methods_tenant_id ON payment_methods (tenant_id);
CREATE INDEX IF NOT EXISTS idx_financial_categories_tenant_id ON financial_categories (tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_tenant_id ON payments (tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_data ON payments (tenant_id, data_pagamento);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_payments_referencia ON payments (referencia_tipo, referencia_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment_id ON payment_transactions (payment_id);
CREATE INDEX IF NOT EXISTS idx_ar_tenant_status ON accounts_receivable (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_ar_customer ON accounts_receivable (customer_id);
CREATE INDEX IF NOT EXISTS idx_ar_vencimento ON accounts_receivable (data_vencimento);
CREATE INDEX IF NOT EXISTS idx_ap_tenant_status ON accounts_payable (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_ap_supplier ON accounts_payable (supplier_id);
CREATE INDEX IF NOT EXISTS idx_ap_vencimento ON accounts_payable (data_vencimento);
CREATE INDEX IF NOT EXISTS idx_financial_budgets_tenant ON financial_budgets (tenant_id, ano);
CREATE INDEX IF NOT EXISTS idx_cash_flow_tenant_data ON cash_flow_entries (tenant_id, data);
