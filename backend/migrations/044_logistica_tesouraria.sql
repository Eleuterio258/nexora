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

CREATE TABLE IF NOT EXISTS logistica.delivery_drivers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(30),
    documento VARCHAR(80),
    carta_conducao VARCHAR(80),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo'
        CHECK (estado IN ('activo','inactivo','suspenso')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistica.delivery_vehicles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    matricula VARCHAR(30) NOT NULL,
    marca VARCHAR(80),
    modelo VARCHAR(80),
    capacidade_kg NUMERIC(18,2),
    estado VARCHAR(20) NOT NULL DEFAULT 'disponivel'
        CHECK (estado IN ('disponivel','em_rota','manutencao','inactivo')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo),
    UNIQUE (tenant_id, matricula)
);

CREATE TABLE IF NOT EXISTS logistica.delivery_routes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    origem VARCHAR(200) NOT NULL,
    destino VARCHAR(200) NOT NULL,
    distancia_km NUMERIC(12,2),
    duracao_estimada_min INTEGER,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistica.delivery_statuses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    ordem INTEGER NOT NULL DEFAULT 0,
    final BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistica.shipments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(60) NOT NULL,
    reference_type VARCHAR(60),
    reference_id BIGINT,
    customer_id BIGINT,
    route_id BIGINT REFERENCES logistica.delivery_routes(id),
    driver_id BIGINT REFERENCES logistica.delivery_drivers(id),
    vehicle_id BIGINT REFERENCES logistica.delivery_vehicles(id),
    status_id BIGINT REFERENCES logistica.delivery_statuses(id),
    endereco_entrega TEXT NOT NULL,
    contacto_entrega VARCHAR(120),
    data_prevista TIMESTAMPTZ,
    data_entrega TIMESTAMPTZ,
    observacoes TEXT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, numero)
);

CREATE TABLE IF NOT EXISTS logistica.shipment_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipment_id BIGINT NOT NULL REFERENCES logistica.shipments(id) ON DELETE CASCADE,
    product_id BIGINT,
    descricao VARCHAR(255) NOT NULL,
    quantidade NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    peso_kg NUMERIC(18,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS logistica.delivery_tracking (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    shipment_id BIGINT NOT NULL REFERENCES logistica.shipments(id) ON DELETE CASCADE,
    status_id BIGINT NOT NULL REFERENCES logistica.delivery_statuses(id),
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    localizacao VARCHAR(200),
    observacoes TEXT,
    registado_por BIGINT,
    registado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_treasury_movements_tenant_date
    ON tesouraria.movements(tenant_id,data_movimento DESC);
CREATE INDEX IF NOT EXISTS idx_treasury_reconciliations_tenant_status
    ON tesouraria.reconciliations(tenant_id,status,periodo_fim DESC);
CREATE INDEX IF NOT EXISTS idx_logistics_shipments_tenant_status
    ON logistica.shipments(tenant_id,status_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logistics_tracking_shipment
    ON logistica.delivery_tracking(shipment_id,registado_em DESC);
