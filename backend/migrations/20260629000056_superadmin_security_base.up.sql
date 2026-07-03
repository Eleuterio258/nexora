-- Base de dados para auditoria, MFA e IP allowlist de superadmin.
-- Nesta fase cria apenas as tabelas; a lógica de verificação é implementada posteriormente.

SET search_path TO auth, public;

-- ── Logs de auditoria (ações sensíveis) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS auth.audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    tenant_id       BIGINT REFERENCES saas.tenants(id) ON DELETE SET NULL,
    acao            TEXT NOT NULL,
    modulo          TEXT,
    recurso         TEXT,
    recurso_id      TEXT,
    ip_address      INET,
    user_agent      TEXT,
    detalhes        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id    ON auth.audit_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_id  ON auth.audit_logs (tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_acao       ON auth.audit_logs (acao);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON auth.audit_logs (created_at);

-- ── Configurações de segurança do superadmin ─────────────────────────────────
CREATE TABLE IF NOT EXISTS auth.superadmin_security_settings (
    chave           TEXT PRIMARY KEY,
    valor           TEXT NOT NULL,
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_por  BIGINT REFERENCES auth.users(id) ON DELETE SET NULL
);

-- ── IP allowlist para superadmin ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS auth.superadmin_ip_allowlist (
    id          BIGSERIAL PRIMARY KEY,
    ip_cidr     INET NOT NULL,
    descricao   TEXT,
    ativo       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by  BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    CONSTRAINT uq_superadmin_ip_allowlist UNIQUE (ip_cidr)
);

CREATE INDEX IF NOT EXISTS idx_superadmin_ip_allowlist_ativo ON auth.superadmin_ip_allowlist (ativo);

-- Valores padrão: MFA e IP allowlist desativados para não quebrar login existente.
INSERT INTO auth.superadmin_security_settings (chave, valor) VALUES
    ('mfa_obrigatorio', 'false'),
    ('ip_allowlist_ativo', 'false')
ON CONFLICT (chave) DO NOTHING;
