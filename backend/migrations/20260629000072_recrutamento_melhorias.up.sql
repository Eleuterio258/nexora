CREATE SCHEMA IF NOT EXISTS recrutamento;
SET search_path TO recrutamento, public;

-- =============================================================================
-- Melhorias no Módulo de Recrutamento
-- Campos adicionais, código de acompanhamento, conta do candidato,
-- campos customizáveis por tenant e configuração de notificações.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Conta do candidato (login opcional)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidatos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(30),
    email_verificado BOOLEAN NOT NULL DEFAULT FALSE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, email)
);

CREATE INDEX IF NOT EXISTS idx_candidatos_tenant_id ON candidatos (tenant_id);

-- -----------------------------------------------------------------------------
-- 2. Campos adicionais na candidatura + código de acompanhamento
-- -----------------------------------------------------------------------------
ALTER TABLE candidaturas
    ADD COLUMN IF NOT EXISTS codigo_acompanhamento VARCHAR(20),
    ADD COLUMN IF NOT EXISTS candidato_id BIGINT,
    ADD COLUMN IF NOT EXISTS pretensao_salarial NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS disponibilidade VARCHAR(50),
    ADD COLUMN IF NOT EXISTS anos_experiencia INT,
    ADD COLUMN IF NOT EXISTS linkedin VARCHAR(255),
    ADD COLUMN IF NOT EXISTS portfolio VARCHAR(255),
    ADD COLUMN IF NOT EXISTS cidade VARCHAR(100),
    ADD COLUMN IF NOT EXISTS provincia VARCHAR(100),
    ADD COLUMN IF NOT EXISTS como_conheceu VARCHAR(100),
    ADD COLUMN IF NOT EXISTS necessidades_especiais TEXT;

-- Garantir unicidade do código de acompanhamento
ALTER TABLE candidaturas
    ADD CONSTRAINT uq_candidaturas_codigo_acompanhamento UNIQUE (codigo_acompanhamento);

-- FK para conta do candidato
ALTER TABLE candidaturas
    ADD CONSTRAINT fk_candidaturas_candidato
        FOREIGN KEY (candidato_id) REFERENCES candidatos(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_candidaturas_candidato_id ON candidaturas (candidato_id);
CREATE INDEX IF NOT EXISTS idx_candidaturas_codigo_acompanhamento ON candidaturas (codigo_acompanhamento);

-- -----------------------------------------------------------------------------
-- 3. Campos customizáveis do formulário por tenant
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidatura_campos_custom (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    label VARCHAR(150) NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('texto','textarea','numero','data','select','multiselect','checkbox','ficheiro')),
    opcoes JSONB NOT NULL DEFAULT '[]',
    obrigatorio BOOLEAN NOT NULL DEFAULT FALSE,
    ordem INT NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, codigo)
);

CREATE INDEX IF NOT EXISTS idx_candidatura_campos_custom_tenant ON candidatura_campos_custom (tenant_id, ativo, ordem);

-- -----------------------------------------------------------------------------
-- 4. Valores dos campos customizados por candidatura
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidatura_valores_custom (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidatura_id BIGINT NOT NULL,
    campo_id BIGINT NOT NULL,
    valor TEXT,
    ficheiro VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_candidatura_valores_candidatura FOREIGN KEY (candidatura_id) REFERENCES candidaturas(id) ON DELETE CASCADE,
    CONSTRAINT fk_candidatura_valores_campo FOREIGN KEY (campo_id) REFERENCES candidatura_campos_custom(id) ON DELETE CASCADE,
    UNIQUE(candidatura_id, campo_id)
);

CREATE INDEX IF NOT EXISTS idx_candidatura_valores_candidatura ON candidatura_valores_custom (candidatura_id);
CREATE INDEX IF NOT EXISTS idx_candidatura_valores_campo ON candidatura_valores_custom (campo_id);

-- -----------------------------------------------------------------------------
-- 5. Configuração de notificações do recrutamento por tenant
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS config_notificacoes (
    tenant_id BIGINT PRIMARY KEY,
    canal_email BOOLEAN NOT NULL DEFAULT TRUE,
    canal_sms BOOLEAN NOT NULL DEFAULT FALSE,
    notificar_candidatura_recebida BOOLEAN NOT NULL DEFAULT TRUE,
    notificar_em_analise BOOLEAN NOT NULL DEFAULT FALSE,
    notificar_entrevista_agendada BOOLEAN NOT NULL DEFAULT TRUE,
    notificar_aprovada BOOLEAN NOT NULL DEFAULT TRUE,
    notificar_rejeitada BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
