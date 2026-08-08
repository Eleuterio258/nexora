-- Reverte a adição de HMAC e permissões por device.

DROP INDEX IF EXISTS hardware.idx_devices_access_key_id;

ALTER TABLE hardware.devices
    DROP COLUMN IF EXISTS access_key_id,
    DROP COLUMN IF EXISTS secret_access_key_hash,
    DROP COLUMN IF EXISTS permissions,
    DROP COLUMN IF EXISTS auth_version,
    DROP COLUMN IF EXISTS hmac_ativo;
