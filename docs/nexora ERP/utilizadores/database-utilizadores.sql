-- Modulo de Utilizadores para PostgreSQL

CREATE TABLE IF NOT EXISTS profiles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    primeiro_nome VARCHAR(100),
    ultimo_nome VARCHAR(100),
    nome_exibicao VARCHAR(150),
    data_nascimento DATE,
    genero VARCHAR(20),
    idioma VARCHAR(20) DEFAULT 'pt',
    timezone VARCHAR(60) DEFAULT 'Africa/Maputo',
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_profiles_user UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS user_preferences (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    chave VARCHAR(100) NOT NULL,
    valor TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_preferences UNIQUE (user_id, chave)
);

CREATE TABLE IF NOT EXISTS user_notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    mensagem TEXT NOT NULL,
    lida BOOLEAN NOT NULL DEFAULT FALSE,
    lida_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_devices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    device_id VARCHAR(120) NOT NULL,
    nome VARCHAR(120),
    plataforma VARCHAR(50),
    user_agent TEXT,
    ultimo_acesso_em TIMESTAMPTZ,
    confiavel BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_devices UNIQUE (user_id, device_id)
);

CREATE TABLE IF NOT EXISTS user_activity (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    modulo VARCHAR(100),
    acao VARCHAR(120) NOT NULL,
    descricao TEXT,
    ip_address VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_tokens (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('refresh', 'email_verify', 'mfa', 'integration')),
    token_hash TEXT NOT NULL,
    expira_em TIMESTAMPTZ,
    revogado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_security_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    evento VARCHAR(100) NOT NULL,
    severidade VARCHAR(20) NOT NULL DEFAULT 'info' CHECK (severidade IN ('info', 'warning', 'critical')),
    detalhe TEXT,
    ip_address VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_avatar (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    ficheiro_url TEXT NOT NULL,
    mime_type VARCHAR(100),
    tamanho_bytes BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_avatar UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS user_settings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    chave VARCHAR(100) NOT NULL,
    valor TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_settings UNIQUE (user_id, chave)
);

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles (user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON user_notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_lida ON user_notifications (lida);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices (user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_id ON user_activity (user_id);
CREATE INDEX IF NOT EXISTS idx_user_tokens_user_id ON user_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_user_security_logs_user_id ON user_security_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_user_avatar_user_id ON user_avatar (user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings (user_id);
