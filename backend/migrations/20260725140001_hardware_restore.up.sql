-- Repõe o schema `hardware`, perdido no rebaseline de migrações de 2026-07-24.
--
-- O baseline (20260724080001_baseline_schema.up.sql) foi gerado a partir do
-- schema de produção mas não incluiu uma única referência a `hardware`, e as
-- migrações originais ficaram em archive/20260710000001_hardware.up.sql e
-- archive/20260710000003_hardware_generico.up.sql sem nunca serem reaplicadas.
--
-- Consequência em produção: RequireDeviceAuth (internal/middleware/device_auth.go)
-- consultava uma tabela inexistente, o erro era tratado como device inválido, e
-- TODOS os endpoints /api/hardware respondiam 401 — incluindo
-- POST /api/hardware/events/generic, por onde a app Android de assiduidade
-- regista os pontos. Nenhum método de marcação funcionava.
--
-- Conteúdo idêntico ao das duas migrações arquivadas, fundido e idempotente.

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

-- ── Suporte a múltiplos fabricantes/drivers ──────────────────────────────────

ALTER TABLE hardware.devices
    ADD COLUMN IF NOT EXISTS driver VARCHAR(60) NOT NULL DEFAULT 'hikvision'
        CHECK (driver IN ('hikvision', 'zkteco', 'generic_rest', 'generic_mqtt', 'custom'));

CREATE INDEX IF NOT EXISTS idx_hardware_devices_driver
    ON hardware.devices(driver);

-- Configurações específicas por driver (ex: URL ISAPI, segredo webhook, tópico MQTT).
CREATE TABLE IF NOT EXISTS hardware.device_configs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES hardware.devices(id) ON DELETE CASCADE,
    chave VARCHAR(100) NOT NULL,
    valor TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (device_id, chave)
);

CREATE INDEX IF NOT EXISTS idx_hardware_device_configs_device
    ON hardware.device_configs(device_id);

-- Registo de drivers disponíveis no sistema.
CREATE TABLE IF NOT EXISTS hardware.drivers (
    codigo VARCHAR(60) PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    versao VARCHAR(20),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO hardware.drivers (codigo, nome, descricao, versao)
VALUES
    ('hikvision', 'Hikvision ISAPI', 'Terminais Hikvision via ISAPI/Push SDK', '1.0'),
    ('zkteco', 'ZKTeco', 'Terminais ZKTeco via REST API/SDK', '1.0'),
    ('generic_rest', 'REST Genérico', 'Webhook/REST normalizado genérico', '1.0'),
    ('generic_mqtt', 'MQTT Genérico', 'Leitores via broker MQTT', '1.0'),
    ('custom', 'Custom', 'Driver personalizado', '1.0')
ON CONFLICT (codigo) DO NOTHING;

-- Templates de impressão digital para identificação 1:N.
CREATE TABLE IF NOT EXISTS hardware.fingerprint_templates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES empresas.companies(id) ON DELETE CASCADE,
    erp_user_id VARCHAR(50) NOT NULL,
    erp_funcionario_id VARCHAR(50),
    finger_type VARCHAR(50) NOT NULL DEFAULT 'right_thumb',
    template_base64 TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, erp_user_id, finger_type)
);

CREATE INDEX IF NOT EXISTS idx_hardware_fingerprint_templates_tenant_user
    ON hardware.fingerprint_templates(tenant_id, erp_user_id);
CREATE INDEX IF NOT EXISTS idx_hardware_fingerprint_templates_tenant_funcionario
    ON hardware.fingerprint_templates(tenant_id, erp_funcionario_id);
