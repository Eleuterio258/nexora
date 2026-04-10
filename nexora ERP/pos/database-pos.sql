-- Modulo POS (Point of Sale) para PostgreSQL

-- ============================================================
-- TERMINAIS POS
-- ============================================================

CREATE TABLE IF NOT EXISTS pos_terminals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    warehouse_id BIGINT NOT NULL,
    caixa_id BIGINT,
    localizacao VARCHAR(150),
    impressora_serie VARCHAR(100),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_pos_terminals UNIQUE (tenant_id, codigo)
);

-- ============================================================
-- SESSOES DE CAIXA
-- ============================================================

CREATE TABLE IF NOT EXISTS pos_sessions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    terminal_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    abertura_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecho_em TIMESTAMPTZ,
    saldo_inicial NUMERIC(18,2) NOT NULL DEFAULT 0,
    saldo_final_declarado NUMERIC(18,2),
    saldo_final_calculado NUMERIC(18,2),
    diferenca_caixa NUMERIC(18,2) GENERATED ALWAYS AS (
        saldo_final_declarado - saldo_final_calculado
    ) STORED,
    total_vendas NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_devolucoes NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_movimentos_entrada NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_movimentos_saida NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes_fecho TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta', 'fechada')),
    CONSTRAINT fk_pos_sessions_terminal FOREIGN KEY (terminal_id) REFERENCES pos_terminals(id)
);

-- Totais por metodo de pagamento no fecho da sessao (reconciliacao)
CREATE TABLE IF NOT EXISTS pos_session_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id BIGINT NOT NULL,
    payment_method_id BIGINT NOT NULL,
    total_vendas NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_devolucoes NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_liquido NUMERIC(18,2) GENERATED ALWAYS AS (total_vendas - total_devolucoes) STORED,
    CONSTRAINT uq_pos_session_payments UNIQUE (session_id, payment_method_id),
    CONSTRAINT fk_session_payments_session FOREIGN KEY (session_id) REFERENCES pos_sessions(id) ON DELETE CASCADE
);

-- ============================================================
-- VENDAS POS
-- ============================================================

CREATE TABLE IF NOT EXISTS pos_sales (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    session_id BIGINT NOT NULL,
    customer_id BIGINT,
    numero VARCHAR(50) NOT NULL,
    sale_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    troco NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'concluida' CHECK (status IN ('rascunho', 'concluida', 'cancelada')),
    cancelada_em TIMESTAMPTZ,
    cancelada_por BIGINT,
    motivo_cancelamento TEXT,
    CONSTRAINT uq_pos_sales UNIQUE (tenant_id, numero),
    CONSTRAINT fk_pos_sales_session FOREIGN KEY (session_id) REFERENCES pos_sessions(id)
);

CREATE TABLE IF NOT EXISTS pos_sale_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pos_sale_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    descricao VARCHAR(255),
    quantidade NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(18,4) NOT NULL CHECK (preco_unitario >= 0),
    desconto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    desconto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_id BIGINT,
    iva_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    iva_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_pos_sale_items_sale FOREIGN KEY (pos_sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE
);

-- ============================================================
-- PAGAMENTOS DA VENDA POS
-- ============================================================

CREATE TABLE IF NOT EXISTS pos_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pos_sale_id BIGINT NOT NULL,
    payment_method_id BIGINT NOT NULL,
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    referencia VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_payments_sale FOREIGN KEY (pos_sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE
);

-- ============================================================
-- DEVOLUCOES POS
-- ============================================================

CREATE TABLE IF NOT EXISTS pos_returns (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    session_id BIGINT NOT NULL,
    pos_sale_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    return_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo TEXT,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    tipo_reembolso VARCHAR(20) NOT NULL DEFAULT 'numerario' CHECK (tipo_reembolso IN ('numerario', 'credito_loja', 'mesmo_metodo')),
    status VARCHAR(20) NOT NULL DEFAULT 'processada' CHECK (status IN ('processada', 'cancelada')),
    CONSTRAINT uq_pos_returns UNIQUE (tenant_id, numero),
    CONSTRAINT fk_pos_returns_session FOREIGN KEY (session_id) REFERENCES pos_sessions(id),
    CONSTRAINT fk_pos_returns_sale FOREIGN KEY (pos_sale_id) REFERENCES pos_sales(id)
);

CREATE TABLE IF NOT EXISTS pos_return_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pos_return_id BIGINT NOT NULL,
    pos_sale_item_id BIGINT NOT NULL,
    quantidade NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(18,4) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    motivo TEXT,
    CONSTRAINT fk_pos_return_items_return FOREIGN KEY (pos_return_id) REFERENCES pos_returns(id) ON DELETE CASCADE
);

-- ============================================================
-- MOVIMENTOS MANUAIS DE CAIXA
-- ============================================================

CREATE TABLE IF NOT EXISTS pos_cash_movements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id BIGINT NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('entrada', 'saida')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    motivo VARCHAR(150) NOT NULL,
    registado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_cash_session FOREIGN KEY (session_id) REFERENCES pos_sessions(id)
);

-- ============================================================
-- INDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_pos_terminals_tenant ON pos_terminals (tenant_id);
CREATE INDEX IF NOT EXISTS idx_pos_sessions_tenant ON pos_sessions (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_pos_sessions_terminal ON pos_sessions (terminal_id);
CREATE INDEX IF NOT EXISTS idx_pos_sessions_user ON pos_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_pos_sales_session ON pos_sales (session_id);
CREATE INDEX IF NOT EXISTS idx_pos_sales_tenant_date ON pos_sales (tenant_id, sale_date);
CREATE INDEX IF NOT EXISTS idx_pos_sales_customer ON pos_sales (customer_id);
CREATE INDEX IF NOT EXISTS idx_pos_sales_status ON pos_sales (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_pos_sale_items_sale ON pos_sale_items (pos_sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_payments_sale ON pos_payments (pos_sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_returns_sale ON pos_returns (pos_sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_cash_movements_session ON pos_cash_movements (session_id);
