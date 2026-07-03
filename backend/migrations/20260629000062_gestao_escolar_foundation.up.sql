-- ============================================================
-- Migration 062: Fundação do módulo Gestão Escolar
-- Objetivo: tornar o módulo autossuficiente em setup from-scratch
-- e preparar a estrutura para múltiplos níveis de ensino.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS gestao_escolar;
SET search_path TO gestao_escolar, public;

-- ------------------------------------------------------------
-- 0. Tabelas legadas (migration 036) necessárias a este setup
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_years (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho'
        CHECK (status IN ('rascunho','activo','encerrado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo),
    CHECK (data_fim >= data_inicio)
);

CREATE TABLE IF NOT EXISTS school_terms (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    peso NUMERIC(6,2) NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto'
        CHECK (status IN ('aberto','encerrado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, school_year_id, codigo),
    CHECK (data_fim >= data_inicio)
);

CREATE TABLE IF NOT EXISTS school_subjects (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    carga_horaria INTEGER,
    nota_minima NUMERIC(6,2) NOT NULL DEFAULT 10,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_fee_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT REFERENCES school_years(id),
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'propina',
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    periodicidade VARCHAR(20) NOT NULL DEFAULT 'mensal',
    dia_vencimento INTEGER,
    classe_nivel VARCHAR(80),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

-- ------------------------------------------------------------
-- 1. Configuração académica por tenant
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_levels (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ordem INTEGER NOT NULL DEFAULT 0,
    nota_minima_aprovacao NUMERIC(6,2) NOT NULL DEFAULT 10,
    escala_maxima NUMERIC(6,2) NOT NULL DEFAULT 20,
    sistema_avaliacao VARCHAR(30) NOT NULL DEFAULT '0-20',
    numero_periodos_padrao INTEGER NOT NULL DEFAULT 3,
    nomenclatura_periodo VARCHAR(30) NOT NULL DEFAULT 'trimestre',
    nomenclatura_serie VARCHAR(30) NOT NULL DEFAULT 'classe',
    idade_minima INTEGER,
    idade_maxima INTEGER,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_cycles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    level_id BIGINT NOT NULL REFERENCES school_levels(id) ON DELETE RESTRICT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ordem INTEGER NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, level_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_series (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    level_id BIGINT NOT NULL REFERENCES school_levels(id) ON DELETE RESTRICT,
    cycle_id BIGINT REFERENCES school_cycles(id) ON DELETE SET NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ordem INTEGER NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, level_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_courses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    level_id BIGINT NOT NULL REFERENCES school_levels(id) ON DELETE RESTRICT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    duracao_anos INTEGER NOT NULL DEFAULT 1,
    modalidade VARCHAR(30) NOT NULL DEFAULT 'presencial',
    grau VARCHAR(60),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_course_subjects (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    course_id BIGINT REFERENCES school_courses(id) ON DELETE CASCADE,
    level_id BIGINT REFERENCES school_levels(id) ON DELETE CASCADE,
    series_id BIGINT REFERENCES school_series(id) ON DELETE CASCADE,
    subject_id BIGINT NOT NULL REFERENCES school_subjects(id) ON DELETE CASCADE,
    obrigatoria BOOLEAN NOT NULL DEFAULT TRUE,
    carga_horaria_semanal INTEGER,
    componente VARCHAR(30) DEFAULT 'teorica',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, course_id, series_id, subject_id)
);

CREATE TABLE IF NOT EXISTS school_academic_config (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL UNIQUE,
    level_id BIGINT REFERENCES school_levels(id) ON DELETE SET NULL,
    nota_minima_aprovacao NUMERIC(6,2) NOT NULL DEFAULT 10,
    escala_maxima NUMERIC(6,2) NOT NULL DEFAULT 20,
    sistema_avaliacao VARCHAR(30) NOT NULL DEFAULT '0-20',
    arredondamento VARCHAR(20) NOT NULL DEFAULT 'decimal_2',
    presenca_minima_percentual NUMERIC(5,2) DEFAULT 75,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS school_evaluation_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    padrao BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

-- ------------------------------------------------------------
-- 2. Professores (antes de turmas e atribuições)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_teachers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    codigo VARCHAR(30) NOT NULL,
    nome_completo VARCHAR(160) NOT NULL,
    genero VARCHAR(20),
    telefone VARCHAR(40),
    email VARCHAR(150),
    documento_identificacao VARCHAR(60),
    especialidade VARCHAR(120),
    carga_horaria_maxima_semanal INTEGER DEFAULT 40,
    status VARCHAR(20) NOT NULL DEFAULT 'activo'
        CHECK (status IN ('activo','inactivo','suspenso')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

-- ------------------------------------------------------------
-- 3. Tabelas base que hoje só existem no snapshot SQL
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_classes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT REFERENCES school_years(id),
    level_id BIGINT REFERENCES school_levels(id) ON DELETE SET NULL,
    series_id BIGINT REFERENCES school_series(id) ON DELETE SET NULL,
    course_id BIGINT REFERENCES school_courses(id) ON DELETE SET NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    nivel VARCHAR(50),
    ano_lectivo VARCHAR(20) NOT NULL,
    turma VARCHAR(20),
    turno VARCHAR(30) DEFAULT 'manha',
    sala VARCHAR(50),
    capacidade INTEGER DEFAULT 0,
    director_teacher_id BIGINT REFERENCES school_teachers(id) ON DELETE SET NULL,
    horario JSONB NOT NULL DEFAULT '[]'::jsonb,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, school_year_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    data_nascimento DATE,
    genero VARCHAR(20),
    encarregado_nome VARCHAR(150),
    encarregado_telefone VARCHAR(30),
    encarregado_email VARCHAR(150),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo'
        CHECK (estado IN ('activo','inactivo','transferido','graduado')),
    documento_tipo VARCHAR(30),
    documento_numero VARCHAR(60),
    nuit VARCHAR(30),
    telefone VARCHAR(30),
    email VARCHAR(120),
    endereco TEXT,
    fotografia_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_enrollments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT REFERENCES school_years(id),
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    class_id BIGINT NOT NULL REFERENCES school_classes(id) ON DELETE RESTRICT,
    numero VARCHAR(50) NOT NULL,
    data_matricula DATE NOT NULL DEFAULT CURRENT_DATE,
    tipo VARCHAR(20) NOT NULL DEFAULT 'nova'
        CHECK (tipo IN ('nova','rematricula','transferencia')),
    status VARCHAR(20) NOT NULL DEFAULT 'activa'
        CHECK (status IN ('activa','suspensa','cancelada','concluida','transferida')),
    observacoes TEXT,
    transferred_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, numero),
    UNIQUE (tenant_id, school_year_id, student_id)
);

CREATE TABLE IF NOT EXISTS school_attendance (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL REFERENCES school_classes(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    subject_id BIGINT REFERENCES school_subjects(id) ON DELETE SET NULL,
    enrollment_id BIGINT REFERENCES school_enrollments(id) ON DELETE SET NULL,
    attendance_date DATE NOT NULL,
    estado VARCHAR(20) NOT NULL
        CHECK (estado IN ('presente','ausente','justificado','atrasado')),
    observacoes TEXT,
    created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS school_fees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL REFERENCES school_enrollments(id) ON DELETE CASCADE,
    fee_plan_id BIGINT REFERENCES school_fee_plans(id) ON DELETE SET NULL,
    student_id BIGINT REFERENCES school_students(id) ON DELETE CASCADE,
    numero VARCHAR(50) NOT NULL,
    descricao VARCHAR(150) NOT NULL,
    mes_referencia VARCHAR(20),
    data_vencimento DATE NOT NULL,
    valor_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_motivo TEXT,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'pendente'
        CHECK (status IN ('pendente','emitida','parcial','paga','cancelada')),
    entidade VARCHAR(20),
    referencia VARCHAR(40),
    emitida_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS school_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_fee_id BIGINT NOT NULL REFERENCES school_fees(id) ON DELETE RESTRICT,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    external_id VARCHAR(100),
    metodo VARCHAR(30) NOT NULL,
    referencia VARCHAR(100),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado'
        CHECK (status IN ('pendente','confirmado','falhado','estornado')),
    conciliado BOOLEAN NOT NULL DEFAULT FALSE,
    pago_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    payload_gateway JSONB,
    created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 4. Ajustes em tabelas já criadas por migration 036
-- ------------------------------------------------------------
-- Adiciona FK de professor nas atribuições. Se já existirem dados inválidos,
-- a constraint é criada como NOT VALID e tenta validar sem abortar a migration.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'gestao_escolar' AND table_name = 'school_teacher_assignments')
       AND NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'gestao_escolar' AND constraint_name = 'fk_school_teacher_assignments_teacher'
    ) THEN
        ALTER TABLE school_teacher_assignments
            ADD CONSTRAINT fk_school_teacher_assignments_teacher
            FOREIGN KEY (teacher_id) REFERENCES school_teachers(id) ON DELETE RESTRICT NOT VALID;

        BEGIN
            ALTER TABLE school_teacher_assignments VALIDATE CONSTRAINT fk_school_teacher_assignments_teacher;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Não foi possível validar FK fk_school_teacher_assignments_teacher: %', SQLERRM;
        END;
    END IF;
END $$;

DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='gestao_escolar' AND table_name='school_years') THEN ALTER TABLE school_years ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='gestao_escolar' AND table_name='school_terms') THEN ALTER TABLE school_terms ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='gestao_escolar' AND table_name='school_subjects') THEN ALTER TABLE school_subjects ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='gestao_escolar' AND table_name='school_fee_plans') THEN ALTER TABLE school_fee_plans ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='gestao_escolar' AND table_name='school_grade_items') THEN ALTER TABLE school_grade_items ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='gestao_escolar' AND table_name='school_grades') THEN ALTER TABLE school_grades ADD COLUMN IF NOT EXISTS lancado_por BIGINT REFERENCES auth.users(id) ON DELETE SET NULL; END IF; END $$;

-- Adicionar colunas novas a tabelas já existentes (compatibilidade com snapshot antigo)
ALTER TABLE school_classes ADD COLUMN IF NOT EXISTS level_id BIGINT REFERENCES school_levels(id) ON DELETE SET NULL;
ALTER TABLE school_classes ADD COLUMN IF NOT EXISTS series_id BIGINT REFERENCES school_series(id) ON DELETE SET NULL;
ALTER TABLE school_classes ADD COLUMN IF NOT EXISTS course_id BIGINT REFERENCES school_courses(id) ON DELETE SET NULL;
ALTER TABLE school_classes ADD COLUMN IF NOT EXISTS turno VARCHAR(30) DEFAULT 'manha';

-- ------------------------------------------------------------
-- 5. Índices de performance
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_school_classes_year ON school_classes(tenant_id, school_year_id);
CREATE INDEX IF NOT EXISTS idx_school_classes_level ON school_classes(tenant_id, level_id);
CREATE INDEX IF NOT EXISTS idx_school_students_tenant ON school_students(tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_year ON school_enrollments(tenant_id, school_year_id);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_class ON school_enrollments(tenant_id, class_id);
CREATE INDEX IF NOT EXISTS idx_school_attendance_date ON school_attendance(tenant_id, attendance_date);
CREATE INDEX IF NOT EXISTS idx_school_fees_status ON school_fees(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_teachers_status ON school_teachers(tenant_id, status);

-- ------------------------------------------------------------
-- 6. Seeds por omissão (idempotentes por tenant)
-- ------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_evaluation_types (tenant_id, codigo, nome, padrao)
SELECT t.id, 'teste', 'Teste', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_evaluation_types et WHERE et.tenant_id = t.id AND et.codigo = 'teste'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_evaluation_types (tenant_id, codigo, nome, padrao)
SELECT t.id, 'trabalho', 'Trabalho', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_evaluation_types et WHERE et.tenant_id = t.id AND et.codigo = 'trabalho'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_evaluation_types (tenant_id, codigo, nome, padrao)
SELECT t.id, 'exame', 'Exame', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_evaluation_types et WHERE et.tenant_id = t.id AND et.codigo = 'exame'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_evaluation_types (tenant_id, codigo, nome, padrao)
SELECT t.id, 'projecto', 'Projecto', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_evaluation_types et WHERE et.tenant_id = t.id AND et.codigo = 'projecto'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_evaluation_types (tenant_id, codigo, nome, padrao)
SELECT t.id, 'oral', 'Avaliação Oral', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_evaluation_types et WHERE et.tenant_id = t.id AND et.codigo = 'oral'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_evaluation_types (tenant_id, codigo, nome, padrao)
SELECT t.id, 'estagio', 'Estágio', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_evaluation_types et WHERE et.tenant_id = t.id AND et.codigo = 'estagio'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_evaluation_types (tenant_id, codigo, nome, padrao)
SELECT t.id, 'defesa', 'Defesa', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_evaluation_types et WHERE et.tenant_id = t.id AND et.codigo = 'defesa'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_levels (tenant_id, codigo, nome, ordem, nota_minima_aprovacao, escala_maxima, sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie)
SELECT t.id, 'primario', 'Ensino Primário', 1, 10, 20, '0-20', 3, 'trimestre', 'classe'
FROM saas.tenants t
WHERE NOT EXISTS (SELECT 1 FROM school_levels l WHERE l.tenant_id = t.id);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_levels (tenant_id, codigo, nome, ordem, nota_minima_aprovacao, escala_maxima, sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie)
SELECT t.id, 'secundario_geral', 'Ensino Secundário Geral', 2, 10, 20, '0-20', 3, 'trimestre', 'classe'
FROM saas.tenants t
WHERE NOT EXISTS (SELECT 1 FROM school_levels l WHERE l.tenant_id = t.id AND l.codigo = 'secundario_geral');
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_levels (tenant_id, codigo, nome, ordem, nota_minima_aprovacao, escala_maxima, sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie)
SELECT t.id, 'tecnico_medio', 'Ensino Técnico Médio', 3, 10, 20, '0-20', 3, 'trimestre', 'ano'
FROM saas.tenants t
WHERE NOT EXISTS (SELECT 1 FROM school_levels l WHERE l.tenant_id = t.id AND l.codigo = 'tecnico_medio');
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_levels (tenant_id, codigo, nome, ordem, nota_minima_aprovacao, escala_maxima, sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie)
SELECT t.id, 'superior_licenciatura', 'Ensino Superior - Licenciatura', 4, 10, 20, '0-20', 2, 'semestre', 'ano'
FROM saas.tenants t
WHERE NOT EXISTS (SELECT 1 FROM school_levels l WHERE l.tenant_id = t.id AND l.codigo = 'superior_licenciatura');
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_levels (tenant_id, codigo, nome, ordem, nota_minima_aprovacao, escala_maxima, sistema_avaliacao, numero_periodos_padrao, nomenclatura_periodo, nomenclatura_serie)
SELECT t.id, 'superior_mestrado', 'Ensino Superior - Mestrado', 5, 14, 20, '0-20', 4, 'semestre', 'ano'
FROM saas.tenants t
WHERE NOT EXISTS (SELECT 1 FROM school_levels l WHERE l.tenant_id = t.id AND l.codigo = 'superior_mestrado');
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_academic_config (tenant_id, nota_minima_aprovacao, escala_maxima, sistema_avaliacao)
SELECT t.id, 10, 20, '0-20'
FROM saas.tenants t
WHERE NOT EXISTS (SELECT 1 FROM school_academic_config c WHERE c.tenant_id = t.id);
    END IF;
END $$;

