CREATE TABLE IF NOT EXISTS crm_lead_sources (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_lead_sources UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS crm_pipelines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_pipelines UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS crm_pipeline_stages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ordem INTEGER NOT NULL,
    probabilidade NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (probabilidade BETWEEN 0 AND 100),
    ganho BOOLEAN NOT NULL DEFAULT FALSE,
    perdido BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_pipeline_stages UNIQUE (pipeline_id, codigo),
    CONSTRAINT fk_crm_pipeline_stages_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm_pipelines(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS crm_leads (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    lead_source_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    empresa VARCHAR(150),
    email VARCHAR(150),
    telefone VARCHAR(30),
    estado VARCHAR(20) NOT NULL DEFAULT 'novo' CHECK (estado IN ('novo','qualificado','convertido','perdido')),
    interesse VARCHAR(255),
    observacoes TEXT,
    owner_user_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_leads UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_crm_leads_source FOREIGN KEY (lead_source_id) REFERENCES crm_lead_sources(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS crm_opportunities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    pipeline_id BIGINT NOT NULL,
    stage_id BIGINT NOT NULL,
    lead_id BIGINT,
    customer_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    valor_estimado NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    probabilidade NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (probabilidade BETWEEN 0 AND 100),
    expected_close_date DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (estado IN ('aberta','ganha','perdida','cancelada')),
    owner_user_id BIGINT,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_opportunities UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_crm_opportunities_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm_pipelines(id) ON DELETE RESTRICT,
    CONSTRAINT fk_crm_opportunities_stage FOREIGN KEY (stage_id) REFERENCES crm_pipeline_stages(id) ON DELETE RESTRICT,
    CONSTRAINT fk_crm_opportunities_lead FOREIGN KEY (lead_id) REFERENCES crm_leads(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS crm_activities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    lead_id BIGINT,
    opportunity_id BIGINT,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('chamada','email','reuniao','nota','tarefa','whatsapp')),
    assunto VARCHAR(150) NOT NULL,
    descricao TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','concluida','cancelada')),
    agendado_para TIMESTAMPTZ,
    concluido_em TIMESTAMPTZ,
    owner_user_id BIGINT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_crm_activities_lead FOREIGN KEY (lead_id) REFERENCES crm_leads(id) ON DELETE CASCADE,
    CONSTRAINT fk_crm_activities_opportunity FOREIGN KEY (opportunity_id) REFERENCES crm_opportunities(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_crm_lead_sources_tenant ON crm_lead_sources (tenant_id);
CREATE INDEX IF NOT EXISTS idx_crm_pipelines_tenant ON crm_pipelines (tenant_id);
CREATE INDEX IF NOT EXISTS idx_crm_pipeline_stages_pipeline ON crm_pipeline_stages (pipeline_id, ordem);
CREATE INDEX IF NOT EXISTS idx_crm_leads_tenant_estado ON crm_leads (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_tenant_estado ON crm_opportunities (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_stage ON crm_opportunities (stage_id);
CREATE INDEX IF NOT EXISTS idx_crm_activities_tenant ON crm_activities (tenant_id, status);
