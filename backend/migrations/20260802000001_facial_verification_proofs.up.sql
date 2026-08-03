CREATE TABLE IF NOT EXISTS rh.facial_verification_uses (
    jti         UUID PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    user_id     BIGINT NOT NULL,
    device_id   VARCHAR(128) NOT NULL,
    used_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_facial_verification_uses_expires_at
    ON rh.facial_verification_uses (expires_at);

COMMENT ON TABLE rh.facial_verification_uses IS
    'JTIs de comprovativos FaceClock consumidos; impede replay de marcacoes faciais.';
