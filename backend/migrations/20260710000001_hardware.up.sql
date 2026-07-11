CREATE SCHEMA IF NOT EXISTS hardware;

-- Dispositivos de acesso (ex: Hikvision DS-K1T673TDGX) associados a um tenant.
CREATE TABLE IF NOT EXISTS hardware.devices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES empresas.companies(id) ON DELETE CASCADE,
    branch_id BIGINT REFERENCES empresas.company_branches(id) ON DELETE SET NULL,
    nome VARCHAR(120) NOT NULL,
    serial_number VARCHAR(100) UNIQUE,
    modelo VARCHAR(60) DEFAULT 'Hikvision DS-K1T673TDGX',
    localizacao VARCHAR(120),
    tipo VARCHAR(30) NOT NULL DEFAULT 'entrada_saida'
        CHECK (tipo IN ('entrada','saida','entrada_saida','sala')),
    ip_permitido INET,
    api_key_hash VARCHAR(64) NOT NULL UNIQUE,
    api_key_prefix VARCHAR(12) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_uso_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Mapeamento entre employeeNo do terminal e entidades do ERP.
CREATE TABLE IF NOT EXISTS hardware.device_users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL REFERENCES hardware.devices(id) ON DELETE CASCADE,
    employee_no VARCHAR(100) NOT NULL,
    entity_type VARCHAR(30) NOT NULL
        CHECK (entity_type IN ('funcionario','aluno','professor')),
    entity_id BIGINT NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, device_id, employee_no)
);

-- Log bruto de eventos recebidos dos terminais.
CREATE TABLE IF NOT EXISTS hardware.device_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL REFERENCES hardware.devices(id) ON DELETE CASCADE,
    event_type VARCHAR(60) NOT NULL,
    employee_no VARCHAR(100),
    event_time TIMESTAMPTZ NOT NULL,
    event_hash VARCHAR(64) UNIQUE,
    raw_payload JSONB,
    processed BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMPTZ,
    presenca_id BIGINT,
    attendance_id BIGINT,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hardware_devices_tenant
    ON hardware.devices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_hardware_devices_serial
    ON hardware.devices(serial_number);
CREATE INDEX IF NOT EXISTS idx_hardware_devices_api_hash
    ON hardware.devices(api_key_hash);

CREATE INDEX IF NOT EXISTS idx_hardware_device_users_device
    ON hardware.device_users(device_id, employee_no);
CREATE INDEX IF NOT EXISTS idx_hardware_device_users_entity
    ON hardware.device_users(tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_hardware_events_tenant_device
    ON hardware.device_events(tenant_id, device_id, created_at);
CREATE INDEX IF NOT EXISTS idx_hardware_events_unprocessed
    ON hardware.device_events(processed, created_at) WHERE processed = FALSE;
CREATE INDEX IF NOT EXISTS idx_hardware_events_hash
    ON hardware.device_events(event_hash);
