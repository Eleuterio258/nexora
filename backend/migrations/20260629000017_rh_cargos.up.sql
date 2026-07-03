SET search_path TO rh, public;

-- ── RF02: catálogo de cargos (posições/funções) ─────────────────────────────
CREATE TABLE IF NOT EXISTS cargos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    salario_min NUMERIC(14,2),
    salario_max NUMERIC(14,2),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cargos_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_cargos_tenant_id ON cargos (tenant_id);

ALTER TABLE funcionarios ADD COLUMN cargo_id BIGINT REFERENCES cargos(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_funcionarios_cargo_id ON funcionarios (cargo_id);

-- ── RNF01: número de funcionário único por tenant (quando preenchido) ──────
CREATE UNIQUE INDEX IF NOT EXISTS uq_funcionarios_tenant_numero
    ON funcionarios (tenant_id, numero_funcionario)
    WHERE numero_funcionario IS NOT NULL AND numero_funcionario <> '';
