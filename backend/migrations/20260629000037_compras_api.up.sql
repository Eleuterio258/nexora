SET search_path TO compras, public;

CREATE TABLE IF NOT EXISTS purchase_requests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    request_date DATE NOT NULL DEFAULT CURRENT_DATE,
    required_date DATE,
    department VARCHAR(120),
    requested_by BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho'
        CHECK (status IN ('rascunho','submetida','aprovada','rejeitada','convertida','cancelada')),
    prioridade VARCHAR(20) NOT NULL DEFAULT 'normal'
        CHECK (prioridade IN ('baixa','normal','alta','urgente')),
    justificacao TEXT,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS purchase_request_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_request_id BIGINT NOT NULL REFERENCES purchase_requests(id) ON DELETE CASCADE,
    product_id BIGINT,
    descricao VARCHAR(255) NOT NULL,
    unidade VARCHAR(20) NOT NULL DEFAULT 'UN',
    quantity NUMERIC(18,4) NOT NULL CHECK (quantity > 0),
    estimated_unit_price NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (estimated_unit_price >= 0),
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE purchase_orders
    ADD COLUMN IF NOT EXISTS purchase_request_id BIGINT REFERENCES purchase_requests(id),
    ADD COLUMN IF NOT EXISTS payment_terms VARCHAR(120);

ALTER TABLE goods_receipts
    ADD COLUMN IF NOT EXISTS supplier_document VARCHAR(100),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE purchase_returns
    ADD COLUMN IF NOT EXISTS warehouse_id BIGINT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE TABLE IF NOT EXISTS purchase_invoices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    purchase_order_id BIGINT REFERENCES purchase_orders(id) ON DELETE RESTRICT,
    goods_receipt_id BIGINT REFERENCES goods_receipts(id) ON DELETE RESTRICT,
    numero VARCHAR(60) NOT NULL,
    supplier_invoice_number VARCHAR(100),
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho'
        CHECK (status IN ('rascunho','emitida','parcial','paga','cancelada')),
    observacoes TEXT,
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, numero),
    UNIQUE NULLS NOT DISTINCT (tenant_id, supplier_id, supplier_invoice_number)
);

CREATE TABLE IF NOT EXISTS purchase_invoice_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_invoice_id BIGINT NOT NULL REFERENCES purchase_invoices(id) ON DELETE CASCADE,
    purchase_order_item_id BIGINT REFERENCES purchase_order_items(id) ON DELETE RESTRICT,
    product_id BIGINT,
    descricao VARCHAR(255) NOT NULL,
    unidade VARCHAR(20) NOT NULL DEFAULT 'UN',
    quantity NUMERIC(18,4) NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(18,2) NOT NULL CHECK (unit_price >= 0),
    desconto NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    tax_rate NUMERIC(8,4) NOT NULL DEFAULT 0 CHECK (tax_rate >= 0),
    tax_amount NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    total NUMERIC(18,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS purchase_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    numero VARCHAR(60) NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    metodo VARCHAR(30) NOT NULL,
    referencia VARCHAR(100),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    valor_alocado NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (valor_alocado >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado'
        CHECK (status IN ('rascunho','confirmado','cancelado')),
    observacoes TEXT,
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS purchase_payment_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_payment_id BIGINT NOT NULL REFERENCES purchase_payments(id) ON DELETE CASCADE,
    purchase_invoice_id BIGINT NOT NULL REFERENCES purchase_invoices(id) ON DELETE RESTRICT,
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (purchase_payment_id, purchase_invoice_id)
);

CREATE INDEX IF NOT EXISTS idx_purchase_requests_tenant_status
    ON purchase_requests(tenant_id,status,request_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_request_items_request
    ON purchase_request_items(purchase_request_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_tenant_status
    ON purchase_orders(tenant_id,status,order_date DESC);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_tenant_date
    ON goods_receipts(tenant_id,receipt_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_returns_tenant_date
    ON purchase_returns(tenant_id,return_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_tenant_status
    ON purchase_invoices(tenant_id,status,due_date);
CREATE INDEX IF NOT EXISTS idx_purchase_invoice_items_invoice
    ON purchase_invoice_items(purchase_invoice_id);
CREATE INDEX IF NOT EXISTS idx_purchase_payments_tenant_date
    ON purchase_payments(tenant_id,payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_payment_items_payment
    ON purchase_payment_items(purchase_payment_id);
