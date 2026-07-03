SET search_path TO rh, public;

-- ── Benefícios: catálogo ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS beneficios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    valor_padrao NUMERIC(14,2),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_beneficios_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_beneficios_tenant_id ON beneficios (tenant_id);

-- ── Benefícios atribuídos a funcionários ────────────────────────────────────
CREATE TABLE IF NOT EXISTS funcionario_beneficios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    beneficio_id BIGINT NOT NULL REFERENCES beneficios(id) ON DELETE CASCADE,
    valor NUMERIC(14,2),
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_funcionario_beneficio UNIQUE (funcionario_id, beneficio_id)
);
CREATE INDEX IF NOT EXISTS idx_funcionario_beneficios_funcionario_id ON funcionario_beneficios (funcionario_id);
