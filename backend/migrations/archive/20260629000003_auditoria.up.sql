CREATE SCHEMA IF NOT EXISTS auditoria;
SET search_path TO auditoria, public;

-- Modulo de Auditoria para PostgreSQL
-- Responsavel por: registo de todas as accoes realizadas por utilizadores em qualquer modulo

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT,
    modulo VARCHAR(100) NOT NULL,
    entidade VARCHAR(100) NOT NULL,
    entidade_id BIGINT,
    acao VARCHAR(100) NOT NULL,
    detalhes JSONB,
    ip_address VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    -- user_id referencia autenticacao.users (sem FK para evitar cascata em logs)
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_id ON audit_logs (tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_modulo ON audit_logs (modulo);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs (created_at);
