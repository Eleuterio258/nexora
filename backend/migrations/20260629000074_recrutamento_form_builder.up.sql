-- Migration 074: Form Builder por Vaga + Tipos de Candidatura configuráveis
-- Permite campos dinâmicos por vaga e activar/desactivar candidatura pública vs conta

SET search_path TO recrutamento, public;

-- 1. Tipos de candidatura configuráveis por vaga
ALTER TABLE vagas
    ADD COLUMN IF NOT EXISTS permite_publica BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS permite_conta   BOOLEAN NOT NULL DEFAULT TRUE;

-- 2. Campos do formulário por vaga (Form Builder)
CREATE TABLE IF NOT EXISTS vaga_campos (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vaga_id    BIGINT NOT NULL REFERENCES vagas(id) ON DELETE CASCADE,
    tenant_id  BIGINT NOT NULL,
    codigo     VARCHAR(50)  NOT NULL,
    label      VARCHAR(150) NOT NULL,
    tipo       VARCHAR(30)  NOT NULL CHECK (tipo IN ('texto','textarea','numero','data','select','multiselect','checkbox','ficheiro')),
    opcoes     JSONB        NOT NULL DEFAULT '[]',
    obrigatorio BOOLEAN     NOT NULL DEFAULT FALSE,
    ordem      INT          NOT NULL DEFAULT 0,
    ativo      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (vaga_id, codigo)
);

CREATE INDEX IF NOT EXISTS idx_vaga_campos_vaga  ON vaga_campos (vaga_id, ativo, ordem);
CREATE INDEX IF NOT EXISTS idx_vaga_campos_tenant ON vaga_campos (tenant_id);

-- 3. Respostas dos campos por vaga (separado dos campos de tenant)
CREATE TABLE IF NOT EXISTS candidatura_respostas_vaga (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    candidatura_id BIGINT NOT NULL REFERENCES candidaturas(id) ON DELETE CASCADE,
    campo_id       BIGINT NOT NULL REFERENCES vaga_campos(id)  ON DELETE CASCADE,
    valor          TEXT,
    ficheiro       VARCHAR(255),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (candidatura_id, campo_id)
);

CREATE INDEX IF NOT EXISTS idx_candidatura_respostas_vaga ON candidatura_respostas_vaga (candidatura_id);
CREATE INDEX IF NOT EXISTS idx_candidatura_respostas_campo ON candidatura_respostas_vaga (campo_id);
