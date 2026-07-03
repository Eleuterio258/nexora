SET search_path TO rh, public;

-- ── Assiduidade: presenças e horas extra ────────────────────────────────────
CREATE TABLE IF NOT EXISTS presencas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    data DATE NOT NULL,
    hora_entrada VARCHAR(5),
    hora_saida VARCHAR(5),
    horas_extra NUMERIC(5,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_presencas_funcionario_data UNIQUE (funcionario_id, data)
);
CREATE INDEX IF NOT EXISTS idx_presencas_funcionario_id ON presencas (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_presencas_tenant_data ON presencas (tenant_id, data);
