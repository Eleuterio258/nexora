CREATE TABLE IF NOT EXISTS logistics_vehicles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    matricula VARCHAR(30) NOT NULL,
    descricao VARCHAR(150),
    capacidade_kg NUMERIC(18,2),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_logistics_vehicles_codigo UNIQUE (tenant_id, codigo),
    CONSTRAINT uq_logistics_vehicles_matricula UNIQUE (tenant_id, matricula)
);

CREATE TABLE IF NOT EXISTS logistics_drivers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(30),
    carta_numero VARCHAR(50),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_logistics_drivers UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistics_routes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    origem VARCHAR(150) NOT NULL,
    destino VARCHAR(150) NOT NULL,
    distancia_km NUMERIC(18,2),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_logistics_routes UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistics_shipments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    source_service VARCHAR(100) NOT NULL,
    source_type VARCHAR(100) NOT NULL,
    source_id BIGINT NOT NULL,
    logistics_route_id BIGINT,
    vehicle_id BIGINT,
    driver_id BIGINT,
    customer_id BIGINT,
    delivery_address TEXT,
    scheduled_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'planeada' CHECK (status IN ('planeada','despachada','em_transito','entregue','cancelada')),
    observacoes TEXT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_logistics_shipments UNIQUE (tenant_id, numero),
    CONSTRAINT fk_logistics_shipments_route FOREIGN KEY (logistics_route_id) REFERENCES logistics_routes(id) ON DELETE SET NULL,
    CONSTRAINT fk_logistics_shipments_vehicle FOREIGN KEY (vehicle_id) REFERENCES logistics_vehicles(id) ON DELETE SET NULL,
    CONSTRAINT fk_logistics_shipments_driver FOREIGN KEY (driver_id) REFERENCES logistics_drivers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS logistics_tracking_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    shipment_id BIGINT NOT NULL,
    evento VARCHAR(30) NOT NULL CHECK (evento IN ('planeado','despachado','em_transito','entregue','falha_entrega','cancelado')),
    localizacao VARCHAR(255),
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    observacoes TEXT,
    event_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_logistics_tracking_events_shipment FOREIGN KEY (shipment_id) REFERENCES logistics_shipments(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_logistics_vehicles_tenant ON logistics_vehicles (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_logistics_drivers_tenant ON logistics_drivers (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_logistics_routes_tenant ON logistics_routes (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_logistics_shipments_tenant_status ON logistics_shipments (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_logistics_tracking_events_tenant ON logistics_tracking_events (tenant_id, event_time DESC);
