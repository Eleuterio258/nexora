CREATE SCHEMA IF NOT EXISTS assinatura_digital;

-- Documentos enviados para assinatura
CREATE TABLE IF NOT EXISTS assinatura_digital.documentos (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    titulo          VARCHAR(255) NOT NULL,
    descricao       TEXT,
    storage_key     VARCHAR(500),
    ficheiro_url    VARCHAR(1000),
    hash_sha256     VARCHAR(64),
    status          VARCHAR(30) DEFAULT 'rascunho' NOT NULL, -- rascunho, pendente, assinado, cancelado, expirado
    created_by      BIGINT NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    data_envio      TIMESTAMPTZ,
    data_conclusao  TIMESTAMPTZ,
    CONSTRAINT documentos_status_check CHECK (status IN ('rascunho','pendente','assinado','cancelado','expirado'))
);

CREATE INDEX IF NOT EXISTS idx_documentos_tenant ON assinatura_digital.documentos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_documentos_status ON assinatura_digital.documentos(status);

-- Signatários de cada documento
CREATE TABLE IF NOT EXISTS assinatura_digital.signatarios (
    id              BIGSERIAL PRIMARY KEY,
    documento_id    BIGINT NOT NULL REFERENCES assinatura_digital.documentos(id) ON DELETE CASCADE,
    tenant_id       BIGINT NOT NULL,
    nome            VARCHAR(255) NOT NULL,
    email           VARCHAR(255),
    nuit            VARCHAR(30),
    bi              VARCHAR(30),
    telefone        VARCHAR(30),
    ordem           INT DEFAULT 1,
    tipo            VARCHAR(30) DEFAULT 'assinatura' NOT NULL, -- assinatura, rubrica, testemunha
    status          VARCHAR(30) DEFAULT 'pendente' NOT NULL, -- pendente, convidado, assinado, recusado
    campo_pagina    INT,
    campo_x         NUMERIC(10,2),
    campo_y         NUMERIC(10,2),
    campo_largura   NUMERIC(10,2),
    campo_altura    NUMERIC(10,2),
    assinado_em     TIMESTAMPTZ,
    assinatura_hash VARCHAR(64),
    assinatura_ip   INET,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT signatarios_status_check CHECK (status IN ('pendente','convidado','assinado','recusado')),
    CONSTRAINT signatarios_tipo_check CHECK (tipo IN ('assinatura','rubrica','testemunha'))
);

CREATE INDEX IF NOT EXISTS idx_signatarios_documento ON assinatura_digital.signatarios(documento_id);
CREATE INDEX IF NOT EXISTS idx_signatarios_tenant ON assinatura_digital.signatarios(tenant_id);

-- Versões assinadas do documento
CREATE TABLE IF NOT EXISTS assinatura_digital.versoes_assinadas (
    id              BIGSERIAL PRIMARY KEY,
    documento_id    BIGINT NOT NULL REFERENCES assinatura_digital.documentos(id) ON DELETE CASCADE,
    tenant_id       BIGINT NOT NULL,
    storage_key     VARCHAR(500) NOT NULL,
    ficheiro_url    VARCHAR(1000),
    hash_sha256     VARCHAR(64),
    signatario_id   BIGINT REFERENCES assinatura_digital.signatarios(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_versoes_documento ON assinatura_digital.versoes_assinadas(documento_id);

-- Logs de auditoria do ciclo de assinatura
CREATE TABLE IF NOT EXISTS assinatura_digital.logs (
    id              BIGSERIAL PRIMARY KEY,
    documento_id    BIGINT NOT NULL REFERENCES assinatura_digital.documentos(id) ON DELETE CASCADE,
    tenant_id       BIGINT NOT NULL,
    signatario_id   BIGINT REFERENCES assinatura_digital.signatarios(id),
    acao            VARCHAR(50) NOT NULL, -- upload, adicionado, removido, enviado, assinado, cancelado
    detalhes        JSONB,
    user_id         BIGINT,
    ip_address      INET,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_logs_documento ON assinatura_digital.logs(documento_id);
