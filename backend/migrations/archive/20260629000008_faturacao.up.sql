CREATE SCHEMA IF NOT EXISTS faturacao;
SET search_path TO faturacao, public;

-- Modulo de Vendas e Faturacao para PostgreSQL

-- ============================================================
-- SERIES DOCUMENTAIS
-- Controla a numeracao sequencial por tipo de documento e tenant.
-- Tipos: ORC (orcamento), ENC (encomenda), GR (guia remessa),
--        FT (fatura), NC (nota credito), RB (recibo)
-- ============================================================

CREATE TABLE IF NOT EXISTS invoice_series (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('ORC', 'ENC', 'GR', 'FT', 'NC', 'RB')),
    prefixo VARCHAR(20) NOT NULL,
    ano INTEGER NOT NULL,
    sequencia INTEGER NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoice_series UNIQUE (tenant_id, tipo, ano)
);

-- ============================================================
-- ORCAMENTOS
-- ============================================================

CREATE TABLE IF NOT EXISTS sales_quotes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    serie_id BIGINT,
    customer_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    quote_date DATE NOT NULL DEFAULT CURRENT_DATE,
    validade DATE,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'enviado', 'aprovado', 'rejeitado', 'convertido', 'expirado')),
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_quotes UNIQUE (tenant_id, numero),
    CONSTRAINT fk_sales_quotes_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_quote_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sales_quote_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    descricao VARCHAR(255),
    quantidade NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(18,4) NOT NULL CHECK (preco_unitario >= 0),
    desconto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    desconto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_id BIGINT,
    imposto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    imposto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_quote_items_quote FOREIGN KEY (sales_quote_id) REFERENCES sales_quotes(id) ON DELETE CASCADE
);

-- ============================================================
-- ENCOMENDAS DE VENDA
-- ============================================================

CREATE TABLE IF NOT EXISTS sales_orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    serie_id BIGINT,
    customer_id BIGINT NOT NULL,
    sales_quote_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    data_entrega_prevista DATE,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'confirmada', 'parcial', 'entregue', 'cancelada')),
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_orders UNIQUE (tenant_id, numero),
    CONSTRAINT fk_sales_orders_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL,
    CONSTRAINT fk_sales_orders_quote FOREIGN KEY (sales_quote_id) REFERENCES sales_quotes(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_order_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sales_order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    descricao VARCHAR(255),
    quantidade NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    quantidade_entregue NUMERIC(18,4) NOT NULL DEFAULT 0,
    preco_unitario NUMERIC(18,4) NOT NULL CHECK (preco_unitario >= 0),
    desconto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    desconto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_id BIGINT,
    imposto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    imposto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_order_items_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE
);

-- ============================================================
-- GUIAS DE REMESSA
-- ============================================================

CREATE TABLE IF NOT EXISTS sales_deliveries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    serie_id BIGINT,
    sales_order_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    delivery_date DATE NOT NULL DEFAULT CURRENT_DATE,
    morada_entrega TEXT,
    observacoes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'emitida' CHECK (status IN ('emitida', 'em_transito', 'entregue', 'cancelada')),
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_deliveries UNIQUE (tenant_id, numero),
    CONSTRAINT fk_deliveries_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
    CONSTRAINT fk_deliveries_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_delivery_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sales_delivery_id BIGINT NOT NULL,
    sales_order_item_id BIGINT,
    product_id BIGINT NOT NULL,
    quantidade_entregue NUMERIC(18,4) NOT NULL CHECK (quantidade_entregue > 0),
    CONSTRAINT fk_delivery_items_delivery FOREIGN KEY (sales_delivery_id) REFERENCES sales_deliveries(id) ON DELETE CASCADE
);

-- ============================================================
-- FATURAS
-- ============================================================

CREATE TABLE IF NOT EXISTS invoices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    serie_id BIGINT,
    customer_id BIGINT NOT NULL,
    sales_order_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    taxa_cambio NUMERIC(14,6) NOT NULL DEFAULT 1,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    saldo_pendente NUMERIC(18,2) GENERATED ALWAYS AS (total - valor_pago) STORED,
    payment_terms VARCHAR(100),
    observacoes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'emitida', 'parcialmente_paga', 'paga', 'cancelada', 'vencida')),
    emitida_em TIMESTAMPTZ,
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoices UNIQUE (tenant_id, numero),
    CONSTRAINT fk_invoices_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL,
    CONSTRAINT fk_invoices_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    descricao VARCHAR(255),
    quantidade NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(18,4) NOT NULL CHECK (preco_unitario >= 0),
    desconto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    desconto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_id BIGINT,
    imposto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    imposto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS invoice_taxes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    tax_id BIGINT,
    nome_imposto VARCHAR(100) NOT NULL,
    taxa NUMERIC(8,4) NOT NULL,
    base_imponivel NUMERIC(18,2) NOT NULL,
    valor_imposto NUMERIC(18,2) NOT NULL,
    CONSTRAINT fk_invoice_taxes_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS invoice_discounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('percentual', 'valor_fixo')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    descricao TEXT,
    CONSTRAINT fk_invoice_discounts_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

-- ============================================================
-- RECIBOS (PAGAMENTOS DE FATURAS)
-- ============================================================

CREATE TABLE IF NOT EXISTS invoice_receipts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    serie_id BIGINT,
    invoice_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method_id BIGINT,
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    referencia VARCHAR(100),
    observacoes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado' CHECK (status IN ('pendente', 'confirmado', 'cancelado')),
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoice_receipts UNIQUE (tenant_id, numero),
    CONSTRAINT fk_receipts_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_receipts_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL
);

-- ============================================================
-- NOTAS DE CREDITO (DOCUMENTO FISCAL INDEPENDENTE)
-- ============================================================

CREATE TABLE IF NOT EXISTS credit_notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    serie_id BIGINT,
    customer_id BIGINT NOT NULL,
    invoice_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    credit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    motivo VARCHAR(255) NOT NULL,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'emitida', 'aplicada', 'cancelada')),
    emitida_em TIMESTAMPTZ,
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_credit_notes UNIQUE (tenant_id, numero),
    CONSTRAINT fk_credit_notes_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    CONSTRAINT fk_credit_notes_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS credit_note_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    credit_note_id BIGINT NOT NULL,
    product_id BIGINT,
    descricao VARCHAR(255) NOT NULL,
    quantidade NUMERIC(18,4) NOT NULL DEFAULT 1,
    preco_unitario NUMERIC(18,4) NOT NULL DEFAULT 0,
    tax_id BIGINT,
    imposto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    imposto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_credit_note_items_nc FOREIGN KEY (credit_note_id) REFERENCES credit_notes(id) ON DELETE CASCADE
);

-- ============================================================
-- DEVOLUCOES DE VENDA (FISICAS — CONTROLO DE STOCK)
-- ============================================================

CREATE TABLE IF NOT EXISTS sales_returns (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    invoice_id BIGINT,
    credit_note_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    return_date DATE NOT NULL DEFAULT CURRENT_DATE,
    observacoes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'recebida', 'processada', 'cancelada')),
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_returns UNIQUE (tenant_id, numero),
    CONSTRAINT fk_returns_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    CONSTRAINT fk_returns_credit_note FOREIGN KEY (credit_note_id) REFERENCES credit_notes(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_return_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sales_return_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantidade NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    motivo TEXT,
    estado_produto VARCHAR(20) DEFAULT 'bom' CHECK (estado_produto IN ('bom', 'danificado', 'defeito')),
    CONSTRAINT fk_return_items_return FOREIGN KEY (sales_return_id) REFERENCES sales_returns(id) ON DELETE CASCADE
);

-- ============================================================
-- INDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_invoice_series_tenant ON invoice_series (tenant_id, tipo, ano);
CREATE INDEX IF NOT EXISTS idx_sales_quotes_tenant ON sales_quotes (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_sales_quotes_customer ON sales_quotes (customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_tenant ON sales_orders (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_sales_orders_customer ON sales_orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_quote ON sales_orders (sales_quote_id);
CREATE INDEX IF NOT EXISTS idx_sales_deliveries_order ON sales_deliveries (sales_order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant ON invoices (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices (customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_order ON invoices (sales_order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices (due_date) WHERE status NOT IN ('paga', 'cancelada');
CREATE INDEX IF NOT EXISTS idx_invoice_receipts_invoice ON invoice_receipts (invoice_id);
CREATE INDEX IF NOT EXISTS idx_credit_notes_tenant ON credit_notes (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_credit_notes_invoice ON credit_notes (invoice_id);
CREATE INDEX IF NOT EXISTS idx_sales_returns_invoice ON sales_returns (invoice_id);
