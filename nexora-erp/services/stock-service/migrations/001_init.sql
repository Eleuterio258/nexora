CREATE TABLE IF NOT EXISTS stock_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    warehouse_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    reserved_quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    available_quantity NUMERIC(18,2) GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    minimum_quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    maximum_quantity NUMERIC(18,2),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id, warehouse_id)
);
CREATE TABLE IF NOT EXISTS stock_movements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('entrada','saida','transferencia_entrada','transferencia_saida','ajuste','reserva','liberacao')),
    quantity NUMERIC(18,2) NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    movement_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_movements_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS stock_adjustments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    adjustment_type VARCHAR(20) NOT NULL CHECK (adjustment_type IN ('positivo','negativo')),
    quantity NUMERIC(18,2) NOT NULL,
    reason TEXT,
    adjusted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_adjustments_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS stock_transfers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    from_warehouse_id BIGINT NOT NULL,
    to_warehouse_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','em_transito','concluida','cancelada')),
    transfer_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_transfers UNIQUE (tenant_id, numero)
);
CREATE TABLE IF NOT EXISTS stock_transfer_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock_transfer_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_sti_transfer FOREIGN KEY (stock_transfer_id) REFERENCES stock_transfers(id) ON DELETE CASCADE,
    CONSTRAINT fk_sti_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id)
);
CREATE TABLE IF NOT EXISTS stock_reservations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa','consumida','cancelada')),
    reserved_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_reservations_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS stock_alerts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    alert_type VARCHAR(30) NOT NULL CHECK (alert_type IN ('stock_minimo','stock_maximo','lote_expirar')),
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto','resolvido','ignorado')),
    mensagem TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_alerts_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_stock_items_tenant ON stock_items (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_items_product ON stock_items (product_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_item ON stock_movements (stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_tenant ON stock_movements (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_transfers_tenant ON stock_transfers (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_alerts_tenant ON stock_alerts (tenant_id);
