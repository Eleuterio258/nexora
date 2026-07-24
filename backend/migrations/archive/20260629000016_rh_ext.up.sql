SET search_path TO rh, public;

-- ── RF01.2: novo tipo de unidade organizacional "projeto" ──────────────────
ALTER TABLE unidades_organizacionais DROP CONSTRAINT unidades_organizacionais_tipo_check;
ALTER TABLE unidades_organizacionais
    ADD CONSTRAINT unidades_organizacionais_tipo_check
    CHECK (tipo IN ('departamento','equipa','divisao','seccao','direccao','gabinete','projeto','outro'));

-- ── RF04.2/RF05.2: ligacao funcionarios <-> auth.users ──────────────────────
ALTER TABLE funcionarios ADD COLUMN user_id BIGINT;
ALTER TABLE funcionarios ADD CONSTRAINT uq_funcionarios_user_id UNIQUE (user_id);
ALTER TABLE funcionarios ADD CONSTRAINT fk_funcionarios_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_funcionarios_user_id ON funcionarios (user_id);

-- ── RF05.1: periodos de avaliacao ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS periodos_avaliacao (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(60) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (estado IN ('aberto','encerrado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_periodos_avaliacao_tenant_nome UNIQUE (tenant_id, nome)
);
CREATE INDEX IF NOT EXISTS idx_periodos_avaliacao_tenant_id ON periodos_avaliacao (tenant_id);

ALTER TABLE avaliacoes ADD COLUMN periodo_id BIGINT;
ALTER TABLE avaliacoes ADD CONSTRAINT fk_avaliacoes_periodo FOREIGN KEY (periodo_id) REFERENCES periodos_avaliacao(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_avaliacoes_periodo_id ON avaliacoes (periodo_id);
ALTER TABLE avaliacoes ALTER COLUMN periodo DROP NOT NULL;
