SET search_path TO rh, public;

-- ── RF: catálogo de horários de trabalho ────────────────────────────────────
CREATE TABLE IF NOT EXISTS horarios_trabalho (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    hora_entrada VARCHAR(5) NOT NULL,
    hora_saida VARCHAR(5) NOT NULL,
    intervalo_inicio VARCHAR(5),
    intervalo_fim VARCHAR(5),
    dias_semana VARCHAR(20) NOT NULL DEFAULT '1,2,3,4,5',
    carga_semanal_horas NUMERIC(5,2),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_horarios_trabalho_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_horarios_trabalho_tenant_id ON horarios_trabalho (tenant_id);

ALTER TABLE funcionarios ADD COLUMN horario_id BIGINT REFERENCES horarios_trabalho(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_funcionarios_horario_id ON funcionarios (horario_id);
