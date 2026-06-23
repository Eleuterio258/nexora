CREATE SCHEMA IF NOT EXISTS recrutamento;
SET search_path TO recrutamento, public;

-- Modulo de Recrutamento (vagas + pipeline de candidaturas)

CREATE TABLE IF NOT EXISTS vagas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    area VARCHAR(100) NOT NULL,
    local VARCHAR(100) NOT NULL DEFAULT 'Maputo, Mocambique',
    regime VARCHAR(50) NOT NULL DEFAULT 'Presencial / Hibrido',
    tipo VARCHAR(50) NOT NULL DEFAULT 'Estagio',
    descricao TEXT NOT NULL,
    sobre_funcao TEXT,
    responsabilidades JSONB NOT NULL DEFAULT '[]',
    req_obrigatorios JSONB NOT NULL DEFAULT '[]',
    req_preferenciais JSONB NOT NULL DEFAULT '[]',
    oferece JSONB NOT NULL DEFAULT '[]',
    ativa BOOLEAN NOT NULL DEFAULT TRUE,
    num_vagas SMALLINT NOT NULL DEFAULT 1 CHECK (num_vagas > 0),
    prazo DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS candidaturas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    vaga_id BIGINT,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    telefone VARCHAR(30),
    vaga_titulo VARCHAR(200) NOT NULL,
    carta TEXT,
    cv_ficheiro VARCHAR(255),
    carta_ficheiro VARCHAR(255),
    ip VARCHAR(45) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'recebida'
        CHECK (estado IN ('recebida','em_analise','entrevista','aprovada','rejeitada')),
    score SMALLINT CHECK (score BETWEEN 1 AND 5),
    responsavel VARCHAR(100),
    entrevista_data TIMESTAMPTZ,
    entrevista_local VARCHAR(200),
    entrevista_link VARCHAR(300),
    entrevista_notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_candidaturas_vaga FOREIGN KEY (vaga_id) REFERENCES vagas(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS candidatura_notas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidatura_id BIGINT NOT NULL,
    autor VARCHAR(100) NOT NULL DEFAULT 'admin',
    tipo VARCHAR(20) NOT NULL DEFAULT 'nota'
        CHECK (tipo IN ('nota','entrevista','avaliacao','sistema')),
    conteudo TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_candidatura_notas_candidatura FOREIGN KEY (candidatura_id) REFERENCES candidaturas(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS contactos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    assunto VARCHAR(255) NOT NULL,
    mensagem TEXT NOT NULL,
    ip VARCHAR(45) NOT NULL,
    lido BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_vagas_tenant_id ON vagas (tenant_id);
CREATE INDEX IF NOT EXISTS idx_vagas_ativa ON vagas (ativa);
CREATE INDEX IF NOT EXISTS idx_candidaturas_tenant_id ON candidaturas (tenant_id);
CREATE INDEX IF NOT EXISTS idx_candidaturas_vaga_id ON candidaturas (vaga_id);
CREATE INDEX IF NOT EXISTS idx_candidaturas_estado ON candidaturas (estado);
CREATE INDEX IF NOT EXISTS idx_candidaturas_email ON candidaturas (email);
CREATE INDEX IF NOT EXISTS idx_candidatura_notas_candidatura_id ON candidatura_notas (candidatura_id);
CREATE INDEX IF NOT EXISTS idx_contactos_tenant_id ON contactos (tenant_id);
CREATE INDEX IF NOT EXISTS idx_contactos_lido ON contactos (lido);
