SET search_path TO rh, public;

-- ── Critérios de Avaliação: catálogo configurável ───────────────────────────
CREATE TABLE IF NOT EXISTS criterios_avaliacao (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    peso NUMERIC(5,2) NOT NULL DEFAULT 1,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_criterios_avaliacao_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE INDEX IF NOT EXISTS idx_criterios_avaliacao_tenant_id ON criterios_avaliacao (tenant_id);

-- ── Avaliações: fluxo rascunho → submetida → aprovada ───────────────────────
ALTER TABLE avaliacoes ADD COLUMN estado VARCHAR(20) NOT NULL DEFAULT 'rascunho'
    CHECK (estado IN ('rascunho', 'submetida', 'aprovada'));
ALTER TABLE avaliacoes ADD COLUMN aprovado_por BIGINT;
ALTER TABLE avaliacoes ADD COLUMN aprovado_em TIMESTAMPTZ;

-- ── Pontuações por critério ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS avaliacao_criterios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    avaliacao_id BIGINT NOT NULL REFERENCES avaliacoes(id) ON DELETE CASCADE,
    criterio_id BIGINT NOT NULL REFERENCES criterios_avaliacao(id) ON DELETE RESTRICT,
    pontuacao NUMERIC(4,2) NOT NULL,
    CONSTRAINT uq_avaliacao_criterios UNIQUE (avaliacao_id, criterio_id)
);
CREATE INDEX IF NOT EXISTS idx_avaliacao_criterios_avaliacao_id ON avaliacao_criterios (avaliacao_id);
