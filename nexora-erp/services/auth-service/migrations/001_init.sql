-- Nexora ERP — Auth Service — Schema inicial
-- PostgreSQL 16

CREATE TABLE IF NOT EXISTS users (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    nome        VARCHAR(150) NOT NULL,
    email       VARCHAR(150) NOT NULL,
    password_hash TEXT NOT NULL,
    telefone    VARCHAR(30),
    estado      VARCHAR(20) NOT NULL DEFAULT 'ativo'
                    CHECK (estado IN ('ativo', 'bloqueado', 'pendente', 'inativo')),
    email_verificado BOOLEAN NOT NULL DEFAULT FALSE,
    ultimo_login_em TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_tenant_email UNIQUE (tenant_id, email)
);

CREATE TABLE IF NOT EXISTS sessions (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token_hash  TEXT NOT NULL UNIQUE,
    ip_address  VARCHAR(64),
    user_agent  TEXT,
    iniciado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_em   TIMESTAMPTZ NOT NULL,
    encerrado_em TIMESTAMPTZ,
    ativa       BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS login_history (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         BIGINT,
    tenant_id       BIGINT NOT NULL,
    email_tentado   VARCHAR(150),
    sucesso         BOOLEAN NOT NULL,
    ip_address      VARCHAR(64),
    user_agent      TEXT,
    motivo_falha    VARCHAR(255),
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_login_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS password_resets (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token_hash  TEXT NOT NULL UNIQUE,
    expira_em   TIMESTAMPTZ NOT NULL,
    usado_em    TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS email_verifications (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token_hash  TEXT NOT NULL UNIQUE,
    expira_em   TIMESTAMPTZ NOT NULL,
    usado_em    TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_email_verifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS api_keys (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    user_id     BIGINT,
    nome        VARCHAR(120) NOT NULL,
    key_prefix  VARCHAR(20) NOT NULL,
    key_hash    TEXT NOT NULL UNIQUE,
    ultimo_uso_em TIMESTAMPTZ,
    expira_em   TIMESTAMPTZ,
    ativa       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_api_keys_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_tenant_id        ON users (tenant_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id        ON sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_ativa          ON sessions (ativa);
CREATE INDEX IF NOT EXISTS idx_sessions_token_hash     ON sessions (token_hash);
CREATE INDEX IF NOT EXISTS idx_login_history_tenant_id ON login_history (tenant_id);
CREATE INDEX IF NOT EXISTS idx_password_resets_user_id ON password_resets (user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_tenant_id      ON api_keys (tenant_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_prefix     ON api_keys (key_prefix);
