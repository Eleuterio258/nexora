SET search_path TO rh, public;

-- ── Morada: campos estruturados adicionais no funcionário ────────────────────
ALTER TABLE funcionarios ADD COLUMN provincia VARCHAR(60);
ALTER TABLE funcionarios ADD COLUMN cidade VARCHAR(60);
ALTER TABLE funcionarios ADD COLUMN bairro VARCHAR(100);

-- ── Contactos de Emergência ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS contactos_emergencia (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    nome VARCHAR(150) NOT NULL,
    parentesco VARCHAR(50),
    telefone VARCHAR(30) NOT NULL,
    email VARCHAR(150),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_contactos_emergencia_funcionario_id ON contactos_emergencia (funcionario_id);

-- ── Documentos do Funcionário ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS documentos_funcionario (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    tipo VARCHAR(30) NOT NULL,
    numero VARCHAR(60),
    data_emissao DATE,
    data_validade DATE,
    ficheiro_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_documentos_funcionario_funcionario_id ON documentos_funcionario (funcionario_id);
