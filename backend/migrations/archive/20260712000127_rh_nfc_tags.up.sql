-- Tags NFC associadas a funcionários, para o método de assiduidade por
-- cartão/tag NFC (POST /nfc/validate no FaceClock).

SET search_path TO rh, public;

CREATE TABLE IF NOT EXISTS nfc_tags (
    id             BIGSERIAL PRIMARY KEY,
    tenant_id      BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    tag_uid        VARCHAR(64) NOT NULL,
    activo         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_nfc_tags_tenant_uid UNIQUE (tenant_id, tag_uid)
);

CREATE INDEX IF NOT EXISTS idx_nfc_tags_funcionario ON nfc_tags (funcionario_id);
