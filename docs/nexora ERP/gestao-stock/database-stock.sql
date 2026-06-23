-- Modulo de Inventario e Stock para PostgreSQL
-- Nota: warehouses e definido em gestao-produtos. Este modulo referencia warehouse_id via FK.

CREATE TABLE IF NOT EXISTS warehouse_locations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(30),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_warehouse_locations UNIQUE (warehouse_id, codigo),
    CONSTRAINT fk_warehouse_locations_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stock_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    warehouse_id BIGINT NOT NULL,
    warehouse_location_id BIGINT,
    quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    reserved_quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    available_quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    minimum_quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    maximum_quantity NUMERIC(18,2),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id, warehouse_id, warehouse_location_id)
);

CREATE TABLE IF NOT EXISTS stock_movements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('entrada', 'saida', 'transferencia_entrada', 'transferencia_saida', 'ajuste', 'reserva', 'liberacao')),
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
    adjustment_type VARCHAR(20) NOT NULL CHECK (adjustment_type IN ('positivo', 'negativo')),
    quantity NUMERIC(18,2) NOT NULL,
    reason TEXT,
    adjusted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_adjustments_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stock_transfers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    from_warehouse_id BIGINT NOT NULL,
    to_warehouse_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'em_transito', 'concluida', 'cancelada')),
    transfer_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_transfers UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS stock_reservations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa', 'consumida', 'cancelada')),
    reserved_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_reservations_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stock_batches (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock_item_id BIGINT NOT NULL,
    batch_number VARCHAR(80) NOT NULL,
    manufacture_date DATE,
    expiry_date DATE,
    quantity NUMERIC(18,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_batches UNIQUE (stock_item_id, batch_number),
    CONSTRAINT fk_stock_batches_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stock_serial_numbers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock_item_id BIGINT NOT NULL,
    serial_number VARCHAR(120) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'disponivel' CHECK (status IN ('disponivel', 'reservado', 'vendido', 'devolvido')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_serial_numbers UNIQUE (serial_number),
    CONSTRAINT fk_stock_serial_numbers_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stock_counts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    warehouse_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'fechado', 'cancelado')),
    count_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_counts UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS stock_count_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock_count_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    system_quantity NUMERIC(18,2) NOT NULL,
    counted_quantity NUMERIC(18,2) NOT NULL,
    difference_quantity NUMERIC(18,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_count_items_count FOREIGN KEY (stock_count_id) REFERENCES stock_counts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stock_alerts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    alert_type VARCHAR(30) NOT NULL CHECK (alert_type IN ('stock_minimo', 'stock_maximo', 'lote_expirar', 'serial_invalido')),
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'resolvido', 'ignorado')),
    mensagem TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_alerts_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stock_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT,
    acao VARCHAR(100) NOT NULL,
    detalhe TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
