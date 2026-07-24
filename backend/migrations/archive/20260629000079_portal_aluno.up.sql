-- Portal de auto-serviço para alunos
-- Credenciais de acesso e sessões independentes do sistema admin

ALTER TABLE gestao_escolar.school_students
    ADD COLUMN IF NOT EXISTS portal_email           text,
    ADD COLUMN IF NOT EXISTS portal_password_hash   text,
    ADD COLUMN IF NOT EXISTS portal_ativo           boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS portal_ultimo_login    timestamptz,
    ADD COLUMN IF NOT EXISTS portal_invite_token    text,
    ADD COLUMN IF NOT EXISTS portal_invite_expires_at timestamptz;

CREATE UNIQUE INDEX IF NOT EXISTS school_students_portal_email_tenant_uidx
    ON gestao_escolar.school_students(tenant_id, portal_email)
    WHERE portal_email IS NOT NULL;

CREATE TABLE IF NOT EXISTS gestao_escolar.portal_sessions (
    id          bigserial    PRIMARY KEY,
    student_id  bigint       NOT NULL REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE,
    tenant_id   bigint       NOT NULL,
    token_hash  text         NOT NULL UNIQUE,
    ip_address  text,
    user_agent  text,
    ativa       boolean      NOT NULL DEFAULT true,
    criada_em   timestamptz  NOT NULL DEFAULT NOW(),
    expira_em   timestamptz  NOT NULL
);

CREATE INDEX IF NOT EXISTS portal_sessions_token_hash_idx  ON gestao_escolar.portal_sessions(token_hash);
CREATE INDEX IF NOT EXISTS portal_sessions_student_id_idx  ON gestao_escolar.portal_sessions(student_id);
CREATE INDEX IF NOT EXISTS portal_sessions_expira_em_idx   ON gestao_escolar.portal_sessions(expira_em);
