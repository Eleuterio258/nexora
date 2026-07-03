SET search_path TO rh, public;

-- ── Processos Disciplinares ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS processos_disciplinares (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL
        CHECK (tipo IN ('advertencia_verbal', 'advertencia_escrita', 'suspensao', 'despedimento', 'outro')),
    motivo TEXT NOT NULL,
    descricao TEXT,
    data_ocorrencia DATE NOT NULL,
    data_abertura DATE NOT NULL DEFAULT CURRENT_DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'aberto'
        CHECK (estado IN ('aberto', 'em_analise', 'decidido', 'arquivado')),
    decisao TEXT,
    data_decisao DATE,
    aberto_por BIGINT,
    decidido_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- aberto_por / decidido_por referenciam auth.users (sem FK)
    CONSTRAINT fk_processos_disciplinares_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_processos_disciplinares_tenant_id ON processos_disciplinares (tenant_id);
CREATE INDEX IF NOT EXISTS idx_processos_disciplinares_funcionario_id ON processos_disciplinares (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_processos_disciplinares_estado ON processos_disciplinares (estado);
