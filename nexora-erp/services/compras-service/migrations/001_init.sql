CREATE TABLE IF NOT EXISTS supplier_groups (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_supplier_groups UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_group_id BIGINT,
    codigo VARCHAR(50),
    nome VARCHAR(150) NOT NULL,
    nuit VARCHAR(30),
    telefone VARCHAR(30),
    email VARCHAR(120),
    moeda_padrao VARCHAR(10) NOT NULL DEFAULT 'MZN',
    prazo_pagamento_dias INTEGER NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (estado IN ('ativo','inativo','bloqueado')),
    observacao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_suppliers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo),
    CONSTRAINT uq_suppliers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit),
    CONSTRAINT fk_suppliers_group FOREIGN KEY (supplier_group_id) REFERENCES supplier_groups(id) ON DELETE SET NULL
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
    tipo VARCHAR(30) NOT NULL DEFAULT 'principal' CHECK (tipo IN ('principal','entrega','cobranca','fiscal')),
    endereco VARCHAR(255) NOT NULL,
    cidade VARCHAR(100),
    provincia VARCHAR(100),
    pais VARCHAR(100) NOT NULL DEFAULT 'Mocambique',
    codigo_postal VARCHAR(30),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_supplier_addresses_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','aprovada','parcial','recebida','cancelada')),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    criado_por BIGINT,
    aprovado_por BIGINT,
    aprovado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_orders UNIQUE (tenant_id, numero),
    CONSTRAINT fk_purchase_orders_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL,
    product_id BIGINT,
    descricao VARCHAR(255) NOT NULL,
    unidade VARCHAR(30) NOT NULL DEFAULT 'UN',
    quantity NUMERIC(18,3) NOT NULL CHECK (quantity > 0),
    received_quantity NUMERIC(18,3) NOT NULL DEFAULT 0 CHECK (received_quantity >= 0),
    unit_price NUMERIC(18,2) NOT NULL CHECK (unit_price >= 0),
    desconto NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    tax_rate NUMERIC(8,4) NOT NULL DEFAULT 0 CHECK (tax_rate >= 0),
    tax_amount NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    total NUMERIC(18,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_purchase_order_items_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS goods_receipts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    purchase_order_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    receipt_date DATE NOT NULL DEFAULT CURRENT_DATE,
    warehouse_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado' CHECK (status IN ('confirmado','cancelado')),
    observacoes TEXT,
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_goods_receipts UNIQUE (tenant_id, numero),
    CONSTRAINT fk_goods_receipts_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE RESTRICT,
    CONSTRAINT fk_goods_receipts_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS goods_receipt_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    goods_receipt_id BIGINT NOT NULL,
    purchase_order_item_id BIGINT NOT NULL,
    product_id BIGINT,
    quantity_received NUMERIC(18,3) NOT NULL CHECK (quantity_received > 0),
    returned_quantity NUMERIC(18,3) NOT NULL DEFAULT 0 CHECK (returned_quantity >= 0),
    unit_cost NUMERIC(18,2) NOT NULL CHECK (unit_cost >= 0),
    lote VARCHAR(80),
    validade DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_goods_receipt_items_receipt FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipts(id) ON DELETE CASCADE,
    CONSTRAINT fk_goods_receipt_items_order_item FOREIGN KEY (purchase_order_item_id) REFERENCES purchase_order_items(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS purchase_returns (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    goods_receipt_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    return_date DATE NOT NULL DEFAULT CURRENT_DATE,
    motivo VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmada' CHECK (status IN ('confirmada','cancelada')),
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_returns UNIQUE (tenant_id, numero),
    CONSTRAINT fk_purchase_returns_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    CONSTRAINT fk_purchase_returns_receipt FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipts(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS purchase_return_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_return_id BIGINT NOT NULL,
    goods_receipt_item_id BIGINT NOT NULL,
    product_id BIGINT,
    quantity NUMERIC(18,3) NOT NULL CHECK (quantity > 0),
    unit_cost NUMERIC(18,2) NOT NULL CHECK (unit_cost >= 0),
    total NUMERIC(18,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_purchase_return_items_return FOREIGN KEY (purchase_return_id) REFERENCES purchase_returns(id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_return_items_receipt_item FOREIGN KEY (goods_receipt_item_id) REFERENCES goods_receipt_items(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_supplier_groups_tenant ON supplier_groups (tenant_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_tenant ON suppliers (tenant_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_tenant_status ON purchase_orders (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier ON purchase_orders (supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_order_items_order ON purchase_order_items (purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_tenant_date ON goods_receipts (tenant_id, receipt_date);
CREATE INDEX IF NOT EXISTS idx_goods_receipt_items_receipt ON goods_receipt_items (goods_receipt_id);
CREATE INDEX IF NOT EXISTS idx_purchase_returns_tenant_date ON purchase_returns (tenant_id, return_date);
CREATE INDEX IF NOT EXISTS idx_purchase_return_items_return ON purchase_return_items (purchase_return_id);
