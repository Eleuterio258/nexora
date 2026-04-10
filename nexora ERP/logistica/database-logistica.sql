-- Modulo de Logistica para PostgreSQL

CREATE TABLE IF NOT EXISTS delivery_drivers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(30),
    carta_conducao VARCHAR(60)
);

CREATE TABLE IF NOT EXISTS delivery_vehicles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    matricula VARCHAR(30) NOT NULL,
    descricao VARCHAR(120),
    capacidade NUMERIC(18,2),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_delivery_vehicles UNIQUE (tenant_id, matricula)
);

CREATE TABLE IF NOT EXISTS delivery_routes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(120) NOT NULL,
    origem VARCHAR(150),
    destino VARCHAR(150)
);

CREATE TABLE IF NOT EXISTS delivery_status (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(80) NOT NULL,
    CONSTRAINT uq_delivery_status UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS shipments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    sales_delivery_id BIGINT,
    delivery_route_id BIGINT,
    delivery_driver_id BIGINT,
    delivery_vehicle_id BIGINT,
    delivery_status_id BIGINT,
    shipment_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_shipments UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS shipment_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipment_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL,
    CONSTRAINT fk_shipment_items_shipment FOREIGN KEY (shipment_id) REFERENCES shipments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS delivery_tracking (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipment_id BIGINT NOT NULL,
    latitude NUMERIC(10,6),
    longitude NUMERIC(10,6),
    tracked_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_text VARCHAR(150),
    CONSTRAINT fk_delivery_tracking_shipment FOREIGN KEY (shipment_id) REFERENCES shipments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS delivery_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    shipment_id BIGINT,
    acao VARCHAR(100) NOT NULL,
    detalhe TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
