-- ============================================================
-- Migration 065: Configuração Avançada do Módulo Escolar
-- Fórmulas de notas, transcrições, descontos e geração de propinas
-- ============================================================

SET search_path TO gestao_escolar, public;

-- ------------------------------------------------------------
-- 1. Fórmulas de cálculo de média por nível/curso/período
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_grade_formulas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    level_id BIGINT REFERENCES school_levels(id) ON DELETE CASCADE,
    course_id BIGINT REFERENCES school_courses(id) ON DELETE CASCADE,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    tipo_periodo VARCHAR(30) NOT NULL DEFAULT 'todos', -- todos, trimestre, semestre
    formula JSONB NOT NULL DEFAULT '{}'::jsonb,
      -- Exemplo: {"avaliacoesContinuas": 60, "exame": 40, "minimoPresenca": 75}
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, level_id, course_id, tipo_periodo),
    CHECK (level_id IS NOT NULL OR course_id IS NOT NULL)
);

-- ------------------------------------------------------------
-- 2. Histórico académico do aluno (transcrição)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_academic_transcripts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    school_year_id BIGINT NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
    enrollment_id BIGINT REFERENCES school_enrollments(id) ON DELETE SET NULL,
    level_id BIGINT REFERENCES school_levels(id) ON DELETE SET NULL,
    series_id BIGINT REFERENCES school_series(id) ON DELETE SET NULL,
    course_id BIGINT REFERENCES school_courses(id) ON DELETE SET NULL,
    class_id BIGINT REFERENCES school_classes(id) ON DELETE SET NULL,
    classificacao_final NUMERIC(6,2),
    resultado VARCHAR(30) NOT NULL DEFAULT 'pendente'
        CHECK (resultado IN ('pendente','aprovado','reprovado','transferido','desistiu')),
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, student_id, school_year_id)
);

-- ------------------------------------------------------------
-- 3. Disciplinas concluídas no histórico
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_transcript_subjects (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    transcript_id BIGINT NOT NULL REFERENCES school_academic_transcripts(id) ON DELETE CASCADE,
    subject_id BIGINT NOT NULL REFERENCES school_subjects(id) ON DELETE RESTRICT,
    nota_final NUMERIC(6,2) NOT NULL,
    nota_maxima NUMERIC(6,2) NOT NULL DEFAULT 20,
    faltas INTEGER DEFAULT 0,
    resultado VARCHAR(20) NOT NULL DEFAULT 'aprovado'
        CHECK (resultado IN ('aprovado','reprovado','dispensado')),
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 4. Descontos e isenções por aluno
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_student_fee_discounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    fee_plan_id BIGINT REFERENCES school_fee_plans(id) ON DELETE CASCADE,
    tipo VARCHAR(20) NOT NULL DEFAULT 'percentagem'
        CHECK (tipo IN ('percentagem','valor_fixo','isencao_total')),
    valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    motivo TEXT,
    aprovado_por BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

-- ------------------------------------------------------------
-- 5. Controlo de geração de cobranças recorrentes
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_fee_generations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    fee_plan_id BIGINT NOT NULL REFERENCES school_fee_plans(id) ON DELETE CASCADE,
    school_year_id BIGINT NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
    periodo_referencia VARCHAR(30) NOT NULL, -- 2025-09, 2025-T1, 2025-S1
    data_geracao TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_cobrancas INTEGER NOT NULL DEFAULT 0,
    valor_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    gerado_por BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    UNIQUE (tenant_id, fee_plan_id, periodo_referencia)
);

-- ------------------------------------------------------------
-- 6. Integração financeira: configuração de contas escolares por tenant
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_financial_config (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL UNIQUE,
    conta_receita_id BIGINT,              -- referência a contabilidade.plano_de_contas (previsto)
    conta_bancaria_id BIGINT,             -- referência a tesouraria.contas_bancarias (snapshot) ou tesouraria.bank_accounts (migration 044)
    centro_custo_id BIGINT,               -- referência a centros_custo.cost_centers (ver migration 069)
    criar_movimento_financeiro BOOLEAN NOT NULL DEFAULT FALSE,
    criar_movimento_tesouraria BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 7. Índices
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_grade_formulas_tenant ON school_grade_formulas(tenant_id, level_id, course_id);
CREATE INDEX IF NOT EXISTS idx_transcripts_student ON school_academic_transcripts(tenant_id, student_id);
CREATE INDEX IF NOT EXISTS idx_transcript_subjects ON school_transcript_subjects(transcript_id, subject_id);
CREATE INDEX IF NOT EXISTS idx_student_discounts ON school_student_fee_discounts(tenant_id, student_id, activo);
CREATE INDEX IF NOT EXISTS idx_fee_generations ON school_fee_generations(tenant_id, fee_plan_id, periodo_referencia);
