CREATE SCHEMA IF NOT EXISTS recrutamento;
SET search_path TO recrutamento, public;

-- Experiências profissionais do candidato
CREATE TABLE IF NOT EXISTS candidato_experiencias (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidato_id BIGINT NOT NULL REFERENCES candidatos(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL,
    cargo VARCHAR(150) NOT NULL,
    empresa VARCHAR(150) NOT NULL,
    local VARCHAR(150),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    actual BOOLEAN NOT NULL DEFAULT FALSE,
    descricao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_candidato_experiencias_candidato
    ON candidato_experiencias(candidato_id);
CREATE INDEX IF NOT EXISTS idx_candidato_experiencias_tenant
    ON candidato_experiencias(tenant_id);

-- Formação académica do candidato
CREATE TABLE IF NOT EXISTS candidato_formacoes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidato_id BIGINT NOT NULL REFERENCES candidatos(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL,
    curso VARCHAR(200) NOT NULL,
    instituicao VARCHAR(200) NOT NULL,
    local VARCHAR(150),
    ano_inicio SMALLINT,
    ano_fim SMALLINT,
    nota VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_candidato_formacoes_candidato
    ON candidato_formacoes(candidato_id);
CREATE INDEX IF NOT EXISTS idx_candidato_formacoes_tenant
    ON candidato_formacoes(tenant_id);

-- Notificações do candidato no portal
CREATE TABLE IF NOT EXISTS candidato_notificacoes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidato_id BIGINT NOT NULL REFERENCES candidatos(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'status',
    titulo VARCHAR(200) NOT NULL,
    corpo TEXT NOT NULL,
    lida BOOLEAN NOT NULL DEFAULT FALSE,
    dados JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_candidato_notificacoes_candidato
    ON candidato_notificacoes(candidato_id);
CREATE INDEX IF NOT EXISTS idx_candidato_notificacoes_candidato_lida
    ON candidato_notificacoes(candidato_id, lida);
CREATE INDEX IF NOT EXISTS idx_candidato_notificacoes_tenant
    ON candidato_notificacoes(tenant_id);

ALTER TABLE candidato_notificacoes
    ADD CONSTRAINT candidato_notificacoes_tipo_check
    CHECK (tipo = ANY (ARRAY['application', 'interview', 'message', 'status', 'job']));
