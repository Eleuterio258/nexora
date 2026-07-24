SET search_path TO rh, public;

-- ── Histórico Salarial ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS historico_salarial (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    salario_anterior NUMERIC(14,2),
    salario_novo NUMERIC(14,2) NOT NULL,
    data_efectiva DATE NOT NULL,
    motivo TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_historico_salarial_funcionario_id ON historico_salarial (funcionario_id);
