-- QR codes de assiduidade, persistidos centralmente no ERP (substitui o dict
-- em memória do processo que o FaceClock usava — não sobrevivia a reinícios
-- nem funcionava com múltiplos workers/instâncias).

SET search_path TO rh, public;

CREATE TABLE IF NOT EXISTS qr_tokens (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    token       VARCHAR(80) NOT NULL,
    location_id VARCHAR(100),
    expires_at  TIMESTAMPTZ NOT NULL,
    used_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_qr_tokens_token UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_qr_tokens_tenant ON qr_tokens (tenant_id);
CREATE INDEX IF NOT EXISTS idx_qr_tokens_expires ON qr_tokens (expires_at);
