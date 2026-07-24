SET search_path TO rh, public;

-- ── Componentes Salariais: catálogo ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS componentes_salariais (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('provento','desconto')),
    forma_calculo VARCHAR(20) NOT NULL DEFAULT 'fixo' CHECK (forma_calculo IN ('fixo','percentual')),
    valor_padrao NUMERIC(14,2),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_componentes_salariais_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_componentes_salariais_tenant_id ON componentes_salariais (tenant_id);

-- ── Componentes Salariais atribuídos a funcionários ─────────────────────────
CREATE TABLE IF NOT EXISTS funcionario_componentes_salariais (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    componente_id BIGINT NOT NULL REFERENCES componentes_salariais(id) ON DELETE CASCADE,
    valor NUMERIC(14,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_funcionario_componente UNIQUE (funcionario_id, componente_id)
);
CREATE INDEX IF NOT EXISTS idx_funcionario_componentes_funcionario_id ON funcionario_componentes_salariais (funcionario_id);
