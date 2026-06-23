-- Modulo de Compras para PostgreSQL

CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(150) NOT NULL,
    nuit VARCHAR(30),
    telefone VARCHAR(30),
    email VARCHAR(120),
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (estado IN ('ativo', 'inativo', 'bloqueado')),
    observacao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_suppliers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo),
    CONSTRAINT uq_suppliers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit)
);

CREATE TABLE IF NOT EXISTS supplier_contacts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    cargo VARCHAR(100),
    telefone VARCHAR(30),
    email VARCHAR(120),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_supplier_contacts_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS supplier_addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'principal' CHECK (tipo IN ('principal', 'entrega', 'cobranca', 'fiscal')),
    endereco VARCHAR(255) NOT NULL,
    cidade VARCHAR(100),
    provincia VARCHAR(100),
    pais VARCHAR(100) NOT NULL DEFAULT 'Mocambique',
    codigo_postal VARCHAR(30),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_supplier_addresses_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_suppliers_tenant_id ON suppliers (tenant_id);
CREATE INDEX IF NOT EXISTS idx_supplier_contacts_supplier_id ON supplier_contacts (supplier_id);
CREATE INDEX IF NOT EXISTS idx_supplier_addresses_supplier_id ON supplier_addresses (supplier_id);

CREATE TABLE IF NOT EXISTS purchase_requests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    requester_user_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'aprovado', 'rejeitado', 'convertido')),
    request_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_requests UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS purchase_request_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_request_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL,
    notes TEXT,
    CONSTRAINT fk_purchase_request_items_request FOREIGN KEY (purchase_request_id) REFERENCES purchase_requests(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    purchase_request_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'aprovado', 'parcial', 'recebido', 'cancelado')),
    order_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_orders UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL,
    unit_price NUMERIC(18,2) NOT NULL,
    total NUMERIC(18,2) NOT NULL,
    CONSTRAINT fk_purchase_order_items_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_receipts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    purchase_order_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    receipt_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'recebido' CHECK (status IN ('recebido', 'parcial', 'cancelado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_receipts UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS purchase_receipt_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_receipt_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity_received NUMERIC(18,2) NOT NULL,
    CONSTRAINT fk_purchase_receipt_items_receipt FOREIGN KEY (purchase_receipt_id) REFERENCES purchase_receipts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_returns (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    purchase_receipt_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    return_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'emitida' CHECK (status IN ('emitida', 'processada', 'cancelada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_returns UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS purchase_return_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_return_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL,
    reason TEXT,
    CONSTRAINT fk_purchase_return_items_return FOREIGN KEY (purchase_return_id) REFERENCES purchase_returns(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_invoices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    purchase_order_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    invoice_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'parcialmente_paga', 'paga', 'cancelada')),
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_invoices UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS purchase_invoice_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_invoice_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL,
    unit_price NUMERIC(18,2) NOT NULL,
    total NUMERIC(18,2) NOT NULL,
    CONSTRAINT fk_purchase_invoice_items_invoice FOREIGN KEY (purchase_invoice_id) REFERENCES purchase_invoices(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    payment_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(18,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado' CHECK (status IN ('pendente', 'confirmado', 'cancelado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS purchase_payment_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_payment_id BIGINT NOT NULL,
    purchase_invoice_id BIGINT NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_purchase_payment_items_payment FOREIGN KEY (purchase_payment_id) REFERENCES purchase_payments(id) ON DELETE CASCADE
);
