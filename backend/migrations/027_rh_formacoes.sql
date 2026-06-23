SET search_path TO rh, public;

-- ── Formações: catálogo ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS formacoes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(20) NOT NULL DEFAULT 'tecnica'
        CHECK (categoria IN ('tecnica', 'comportamental', 'obrigatoria', 'outra')),
    duracao_horas NUMERIC(6,2),
    entidade_formadora VARCHAR(150),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_formacoes_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_formacoes_tenant_id ON formacoes (tenant_id);

-- ── Formações: participação de funcionários ─────────────────────────────────
CREATE TABLE IF NOT EXISTS funcionario_formacoes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    formacao_id BIGINT NOT NULL REFERENCES formacoes(id) ON DELETE RESTRICT,
    data_inicio DATE NOT NULL,
    data_fim DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'planeada'
        CHECK (estado IN ('planeada', 'em_curso', 'concluida', 'cancelada')),
    nota NUMERIC(4,2),
    certificado_url TEXT,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_funcionario_formacoes_funcionario_id ON funcionario_formacoes (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_funcionario_formacoes_formacao_id ON funcionario_formacoes (formacao_id);
