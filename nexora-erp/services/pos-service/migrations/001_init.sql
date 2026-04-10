CREATE TABLE IF NOT EXISTS pos_terminals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    warehouse_id BIGINT,
    caixa_id BIGINT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_pos_terminals UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS pos_sessions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    terminal_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ,
    opening_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    closing_amount NUMERIC(18,2),
    status VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta','fechada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_sessions_terminal FOREIGN KEY (terminal_id) REFERENCES pos_terminals(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS pos_catalog_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    codigo_barra VARCHAR(80),
    preco_venda NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_pos_catalog_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id)
);

CREATE TABLE IF NOT EXISTS pos_sales (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    pos_session_id BIGINT NOT NULL,
    terminal_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    customer_id BIGINT,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_recebido NUMERIC(18,2) NOT NULL DEFAULT 0,
    troco NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','concluida','cancelada')),
    sold_at TIMESTAMPTZ,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_pos_sales UNIQUE (tenant_id, numero),
    CONSTRAINT fk_pos_sales_session FOREIGN KEY (pos_session_id) REFERENCES pos_sessions(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pos_sales_terminal FOREIGN KEY (terminal_id) REFERENCES pos_terminals(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS pos_sale_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pos_sale_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    descricao VARCHAR(255),
    quantidade NUMERIC(18,2) NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(18,2) NOT NULL CHECK (preco_unitario >= 0),
    desconto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_sale_items_sale FOREIGN KEY (pos_sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS pos_sale_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pos_sale_id BIGINT NOT NULL,
    payment_method_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('numerario','transferencia','tpa','mpesa','emola','outro')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    referencia VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_sale_payments_sale FOREIGN KEY (pos_sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pos_terminals_tenant ON pos_terminals (tenant_id);
CREATE INDEX IF NOT EXISTS idx_pos_sessions_tenant ON pos_sessions (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_pos_catalog_items_tenant ON pos_catalog_items (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_pos_sales_tenant ON pos_sales (tenant_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pos_sale_items_sale ON pos_sale_items (pos_sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_sale_payments_sale ON pos_sale_payments (pos_sale_id);
