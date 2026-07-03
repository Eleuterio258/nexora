CREATE SCHEMA IF NOT EXISTS crm;
SET search_path TO crm, public;

-- Modulo de CRM (Leads + Oportunidades + Atividades)

CREATE TABLE IF NOT EXISTS leads (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    empresa VARCHAR(150),
    email VARCHAR(255),
    telefone VARCHAR(30),
    origem VARCHAR(50) NOT NULL DEFAULT 'outro'
        CHECK (origem IN ('site','referencia','redes_sociais','evento','chamada_fria','email','anuncio','outro')),
    estado VARCHAR(20) NOT NULL DEFAULT 'novo'
        CHECK (estado IN ('novo','contactado','qualificado','desqualificado','convertido')),
    responsavel VARCHAR(100),
    notas TEXT,
    cliente_id BIGINT,
    convertido_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oportunidades (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    lead_id BIGINT,
    cliente_id BIGINT,
    estagio VARCHAR(20) NOT NULL DEFAULT 'novo'
        CHECK (estagio IN ('novo','qualificado','proposta','negociacao','ganho','perdido')),
    valor_estimado NUMERIC(18,2) DEFAULT 0 CHECK (valor_estimado >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    probabilidade SMALLINT NOT NULL DEFAULT 0 CHECK (probabilidade BETWEEN 0 AND 100),
    data_fecho_prevista DATE,
    data_fecho_real DATE,
    motivo_perda TEXT,
    responsavel VARCHAR(100),
    descricao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_oportunidades_lead FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS atividades (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    lead_id BIGINT,
    oportunidade_id BIGINT,
    tipo VARCHAR(20) NOT NULL DEFAULT 'nota'
        CHECK (tipo IN ('nota','tarefa','chamada','reuniao','email')),
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    data_atividade TIMESTAMPTZ,
    concluida BOOLEAN NOT NULL DEFAULT FALSE,
    responsavel VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_atividades_lead FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE,
    CONSTRAINT fk_atividades_oportunidade FOREIGN KEY (oportunidade_id) REFERENCES oportunidades(id) ON DELETE CASCADE,
    CONSTRAINT chk_atividades_link CHECK (lead_id IS NOT NULL OR oportunidade_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_leads_tenant_id ON leads (tenant_id);
CREATE INDEX IF NOT EXISTS idx_leads_estado ON leads (estado);
CREATE INDEX IF NOT EXISTS idx_leads_responsavel ON leads (responsavel);
CREATE INDEX IF NOT EXISTS idx_leads_email ON leads (email);

CREATE INDEX IF NOT EXISTS idx_oportunidades_tenant_id ON oportunidades (tenant_id);
CREATE INDEX IF NOT EXISTS idx_oportunidades_estagio ON oportunidades (estagio);
CREATE INDEX IF NOT EXISTS idx_oportunidades_lead_id ON oportunidades (lead_id);
CREATE INDEX IF NOT EXISTS idx_oportunidades_cliente_id ON oportunidades (cliente_id);
CREATE INDEX IF NOT EXISTS idx_oportunidades_responsavel ON oportunidades (responsavel);

CREATE INDEX IF NOT EXISTS idx_atividades_tenant_id ON atividades (tenant_id);
CREATE INDEX IF NOT EXISTS idx_atividades_lead_id ON atividades (lead_id);
CREATE INDEX IF NOT EXISTS idx_atividades_oportunidade_id ON atividades (oportunidade_id);
CREATE INDEX IF NOT EXISTS idx_atividades_tipo ON atividades (tipo);
CREATE INDEX IF NOT EXISTS idx_atividades_concluida ON atividades (concluida);
CREATE INDEX IF NOT EXISTS idx_atividades_data ON atividades (data_atividade);
