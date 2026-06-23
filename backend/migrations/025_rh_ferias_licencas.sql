SET search_path TO rh, public;

-- ── Tipos de Ausência: catálogo configurável ────────────────────────────────
CREATE TABLE IF NOT EXISTS tipos_ausencia (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(60) NOT NULL,
    dias_anuais NUMERIC(5,2),
    remunerada BOOLEAN NOT NULL DEFAULT TRUE,
    afeta_saldo BOOLEAN NOT NULL DEFAULT FALSE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tipos_ausencia_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_tipos_ausencia_tenant_id ON tipos_ausencia (tenant_id);

-- ── Ausências: tipo passa a referenciar o catálogo; novos estados ──────────
ALTER TABLE ausencias ALTER COLUMN tipo DROP NOT NULL;
ALTER TABLE ausencias ADD COLUMN tipo_id BIGINT REFERENCES tipos_ausencia(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS idx_ausencias_tipo_id ON ausencias (tipo_id);

ALTER TABLE ausencias DROP CONSTRAINT ausencias_estado_check;
ALTER TABLE ausencias ADD CONSTRAINT ausencias_estado_check
    CHECK (estado IN ('pendente', 'aprovado', 'rejeitado', 'gozada', 'cancelada'));

-- ── Saldos de férias/licenças por funcionário e ano ─────────────────────────
CREATE TABLE IF NOT EXISTS saldos_ausencia (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    tipo_ausencia_id BIGINT NOT NULL REFERENCES tipos_ausencia(id) ON DELETE CASCADE,
    ano INTEGER NOT NULL,
    dias_atribuidos NUMERIC(5,2) NOT NULL DEFAULT 0,
    dias_usados NUMERIC(5,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_saldos_ausencia UNIQUE (funcionario_id, tipo_ausencia_id, ano)
);
CREATE INDEX IF NOT EXISTS idx_saldos_ausencia_funcionario_id ON saldos_ausencia (funcionario_id);
