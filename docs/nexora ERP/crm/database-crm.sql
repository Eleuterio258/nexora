-- Modulo CRM para PostgreSQL

CREATE TABLE IF NOT EXISTS crm_pipelines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_pipelines UNIQUE (tenant_id, nome)
);

CREATE TABLE IF NOT EXISTS crm_stages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline_id BIGINT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    ordem INTEGER NOT NULL DEFAULT 0,
    probabilidade NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (probabilidade BETWEEN 0 AND 100),
    tipo VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (tipo IN ('aberta', 'ganha', 'perdida')),
    cor VARCHAR(20),
    CONSTRAINT uq_crm_stages UNIQUE (pipeline_id, nome),
    CONSTRAINT fk_crm_stages_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm_pipelines(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS crm_leads (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    empresa VARCHAR(150),
    email VARCHAR(120),
    telefone VARCHAR(30),
    origem VARCHAR(50) CHECK (origem IN ('website', 'indicacao', 'redes_sociais', 'evento', 'email', 'outro')),
    status VARCHAR(20) NOT NULL DEFAULT 'novo' CHECK (status IN ('novo', 'contactado', 'qualificado', 'desqualificado', 'convertido')),
    responsavel_id BIGINT,
    observacao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS crm_opportunities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    pipeline_id BIGINT NOT NULL,
    stage_id BIGINT NOT NULL,
    customer_id BIGINT,
    lead_id BIGINT,
    titulo VARCHAR(200) NOT NULL,
    valor NUMERIC(18,2),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    probabilidade NUMERIC(5,2) CHECK (probabilidade BETWEEN 0 AND 100),
    data_fecho_prevista DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta', 'ganha', 'perdida', 'cancelada')),
    responsavel_id BIGINT,
    motivo_perda TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_crm_opportunities_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm_pipelines(id),
    CONSTRAINT fk_crm_opportunities_stage FOREIGN KEY (stage_id) REFERENCES crm_stages(id)
);

CREATE TABLE IF NOT EXISTS crm_contacts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    customer_id BIGINT,
    lead_id BIGINT,
    nome VARCHAR(150) NOT NULL,
    cargo VARCHAR(100),
    email VARCHAR(120),
    telefone VARCHAR(30),
    linkedin VARCHAR(200),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS crm_activities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    opportunity_id BIGINT,
    lead_id BIGINT,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('chamada', 'reuniao', 'email', 'tarefa', 'nota', 'demo')),
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    data_prevista TIMESTAMPTZ,
    data_realizada TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'realizada', 'cancelada')),
    user_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_crm_activities_opportunity FOREIGN KEY (opportunity_id) REFERENCES crm_opportunities(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS crm_notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    opportunity_id BIGINT,
    lead_id BIGINT,
    texto TEXT NOT NULL,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_crm_notes_opportunity FOREIGN KEY (opportunity_id) REFERENCES crm_opportunities(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS crm_tags (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(80) NOT NULL,
    cor VARCHAR(20),
    CONSTRAINT uq_crm_tags UNIQUE (tenant_id, nome)
);

CREATE TABLE IF NOT EXISTS crm_tag_links (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    crm_tag_id BIGINT NOT NULL,
    entity_type VARCHAR(20) NOT NULL CHECK (entity_type IN ('lead', 'opportunity', 'contact')),
    entity_id BIGINT NOT NULL,
    CONSTRAINT uq_crm_tag_links UNIQUE (crm_tag_id, entity_type, entity_id),
    CONSTRAINT fk_crm_tag_links_tag FOREIGN KEY (crm_tag_id) REFERENCES crm_tags(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_crm_leads_tenant_id ON crm_leads (tenant_id);
CREATE INDEX IF NOT EXISTS idx_crm_leads_status ON crm_leads (status);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_tenant_id ON crm_opportunities (tenant_id);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_stage_id ON crm_opportunities (stage_id);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_status ON crm_opportunities (status);
CREATE INDEX IF NOT EXISTS idx_crm_activities_opportunity_id ON crm_activities (opportunity_id);
CREATE INDEX IF NOT EXISTS idx_crm_activities_status ON crm_activities (status);
CREATE INDEX IF NOT EXISTS idx_crm_contacts_customer_id ON crm_contacts (customer_id);
