CREATE SCHEMA IF NOT EXISTS tesouraria;
CREATE SCHEMA IF NOT EXISTS logistica;

CREATE TABLE IF NOT EXISTS tesouraria.bank_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    banco VARCHAR(120) NOT NULL,
    numero_conta VARCHAR(80) NOT NULL,
    iban VARCHAR(80),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    saldo_inicial NUMERIC(18,2) NOT NULL DEFAULT 0,
    saldo_actual NUMERIC(18,2) NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo),
    UNIQUE (tenant_id, banco, numero_conta)
);

CREATE TABLE IF NOT EXISTS tesouraria.cash_registers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    saldo_inicial NUMERIC(18,2) NOT NULL DEFAULT 0,
    saldo_actual NUMERIC(18,2) NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS tesouraria.movements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    bank_account_id BIGINT REFERENCES tesouraria.bank_accounts(id),
    cash_register_id BIGINT REFERENCES tesouraria.cash_registers(id),
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('recebimento','pagamento')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    data_movimento DATE NOT NULL DEFAULT CURRENT_DATE,
    metodo VARCHAR(40),
    referencia VARCHAR(100),
    descricao TEXT,
    reference_type VARCHAR(60),
    reference_id BIGINT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK ((bank_account_id IS NOT NULL)::int + (cash_register_id IS NOT NULL)::int = 1)
);

CREATE TABLE IF NOT EXISTS tesouraria.reconciliations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    bank_account_id BIGINT NOT NULL REFERENCES tesouraria.bank_accounts(id),
    periodo_inicio DATE NOT NULL,
    periodo_fim DATE NOT NULL,
    saldo_extracto NUMERIC(18,2) NOT NULL,
    saldo_sistema NUMERIC(18,2) NOT NULL DEFAULT 0,
    diferenca NUMERIC(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'aberta'
        CHECK (status IN ('aberta','fechada')),
    observacoes TEXT,
    criada_por BIGINT,
    fechada_por BIGINT,
    fechada_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (periodo_fim >= periodo_inicio),
    UNIQUE (tenant_id, bank_account_id, periodo_inicio, periodo_fim)
);

CREATE TABLE IF NOT EXISTS logistica.logistics_drivers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(30),
    carta_numero VARCHAR(80),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistica.logistics_vehicles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    matricula VARCHAR(30) NOT NULL,
    descricao VARCHAR(200),
    capacidade_kg NUMERIC(18,2),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo),
    UNIQUE (tenant_id, matricula)
);

CREATE TABLE IF NOT EXISTS logistica.logistics_routes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    origem VARCHAR(200) NOT NULL,
    destino VARCHAR(200) NOT NULL,
    distancia_km NUMERIC(12,2),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistica.logistics_shipments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(60) NOT NULL,
    source_service VARCHAR(60) NOT NULL DEFAULT 'logistica',
    source_type VARCHAR(60),
    source_id BIGINT,
    logistics_route_id BIGINT REFERENCES logistica.logistics_routes(id),
    vehicle_id BIGINT REFERENCES logistica.logistics_vehicles(id),
    driver_id BIGINT REFERENCES logistica.logistics_drivers(id),
    customer_id BIGINT,
    delivery_address TEXT,
    scheduled_date DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'planeada'
        CHECK (status IN ('planeada','em_transito','entregue','cancelada')),
    observacoes TEXT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS logistica.logistics_tracking_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    shipment_id BIGINT NOT NULL REFERENCES logistica.logistics_shipments(id) ON DELETE CASCADE,
    evento VARCHAR(60) NOT NULL,
    localizacao VARCHAR(200),
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    observacoes TEXT,
    event_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_treasury_movements_tenant_date
    ON tesouraria.movements(tenant_id,data_movimento DESC);
CREATE INDEX IF NOT EXISTS idx_treasury_reconciliations_tenant_status
    ON tesouraria.reconciliations(tenant_id,status,periodo_fim DESC);
CREATE INDEX IF NOT EXISTS idx_logistics_shipments_tenant_status
    ON logistica.logistics_shipments(tenant_id,status,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logistics_tracking_shipment
    ON logistica.logistics_tracking_events(shipment_id,event_time DESC);
