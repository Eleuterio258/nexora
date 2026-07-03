-- Portal do Encarregado: credenciais + sessões

ALTER TABLE gestao_escolar.school_guardians
    ADD COLUMN IF NOT EXISTS portal_email             text,
    ADD COLUMN IF NOT EXISTS portal_password_hash     text,
    ADD COLUMN IF NOT EXISTS portal_ativo             boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS portal_ultimo_login      timestamptz,
    ADD COLUMN IF NOT EXISTS portal_invite_token      text,
    ADD COLUMN IF NOT EXISTS portal_invite_expires_at timestamptz,
    ADD COLUMN IF NOT EXISTS portal_email_verificado  boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS portal_login_tentativas  int     NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS portal_bloqueado_ate     timestamptz;

-- portal_email único por tenant (um login por email por escola)
CREATE UNIQUE INDEX IF NOT EXISTS school_guardians_portal_email_tenant_uidx
    ON gestao_escolar.school_guardians(tenant_id, portal_email)
    WHERE portal_email IS NOT NULL;

-- Sessões do portal do encarregado (por email, suporta multi-educando)
CREATE TABLE IF NOT EXISTS gestao_escolar.guardian_portal_sessions (
    id            bigserial    PRIMARY KEY,
    guardian_email text        NOT NULL,
    tenant_id     bigint       NOT NULL,
    token_hash    text         NOT NULL UNIQUE,
    ip_address    text,
    user_agent    text,
    ativa         boolean      NOT NULL DEFAULT true,
    criada_em     timestamptz  NOT NULL DEFAULT NOW(),
    expira_em     timestamptz  NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_guardian_sessions_email_tenant
    ON gestao_escolar.guardian_portal_sessions(guardian_email, tenant_id)
    WHERE ativa = true;
