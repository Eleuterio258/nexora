-- Adiciona suporte a HMAC-SHA256 e permissões RBAC por device.
-- A autenticação por X-API-Key simples continua disponível enquanto
-- hmac_ativo=false (modo híbrido), permitindo migração gradual.

ALTER TABLE hardware.devices
    ADD COLUMN IF NOT EXISTS access_key_id VARCHAR(64) UNIQUE,
    ADD COLUMN IF NOT EXISTS secret_access_key_hash VARCHAR(64),
    ADD COLUMN IF NOT EXISTS permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS auth_version VARCHAR(30) NOT NULL DEFAULT 'NEXORA-HMAC-SHA256-V1',
    ADD COLUMN IF NOT EXISTS hmac_ativo BOOLEAN NOT NULL DEFAULT FALSE;

-- Índice para lookup rápido do access_key_id durante verificação HMAC.
CREATE INDEX IF NOT EXISTS idx_devices_access_key_id
    ON hardware.devices (access_key_id);

COMMENT ON COLUMN hardware.devices.access_key_id IS 'Identificador público do device para HMAC (ex.: nxd_...)';
COMMENT ON COLUMN hardware.devices.secret_access_key_hash IS 'SHA-256 do segredo HMAC do device';
COMMENT ON COLUMN hardware.devices.permissions IS 'Lista JSON de permissões RBAC do device (ex.: ["assiduidade:qr:write"])';
COMMENT ON COLUMN hardware.devices.auth_version IS 'Versão do protocolo HMAC (ex.: NEXORA-HMAC-SHA256-V1)';
COMMENT ON COLUMN hardware.devices.hmac_ativo IS 'Se true, o device deve autenticar-se obrigatoriamente por HMAC';
