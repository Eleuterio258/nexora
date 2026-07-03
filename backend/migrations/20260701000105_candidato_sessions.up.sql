-- 105_candidato_sessions.up.sql
-- Sessões revogáveis para candidatos do portal público de recrutamento.
-- Permite invalidar tokens individuais sem expirar o JWT.

CREATE TABLE IF NOT EXISTS recrutamento.candidato_sessions (
    id          bigserial PRIMARY KEY,
    candidato_id bigint    NOT NULL REFERENCES recrutamento.candidatos(id) ON DELETE CASCADE,
    token_hash  text       NOT NULL UNIQUE,   -- SHA-256 hex do JWT
    ip          inet,
    user_agent  text,
    criado_em   timestamptz NOT NULL DEFAULT NOW(),
    expira_em   timestamptz NOT NULL,
    revogado_em timestamptz
);

CREATE INDEX IF NOT EXISTS idx_candidato_sessions_candidato ON recrutamento.candidato_sessions(candidato_id);
CREATE INDEX IF NOT EXISTS idx_candidato_sessions_token     ON recrutamento.candidato_sessions(token_hash);
