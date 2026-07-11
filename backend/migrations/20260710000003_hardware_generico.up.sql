-- Extensão do módulo hardware para suporte a múltiplos fabricantes/drivers.

-- Driver associado a cada dispositivo.
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
