-- ============================================================
-- Migration 064: Ocorrências Disciplinares e Méritos Escolares
-- ============================================================

SET search_path TO gestao_escolar, public;

-- ------------------------------------------------------------
-- 1. Tipos de ocorrência e sanção
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_incident_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    gravidade VARCHAR(20) NOT NULL DEFAULT 'media'
        CHECK (gravidade IN ('leve','media','grave','muito_grave')),
    requer_encarregado BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_sanction_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    gravidade VARCHAR(20) NOT NULL DEFAULT 'media'
        CHECK (gravidade IN ('leve','media','grave','muito_grave')),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

-- ------------------------------------------------------------
-- 2. Ocorrências disciplinares
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_student_incidents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    enrollment_id BIGINT REFERENCES school_enrollments(id) ON DELETE SET NULL,
    incident_type_id BIGINT REFERENCES school_incident_types(id) ON DELETE SET NULL,
    reported_by BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    data_ocorrencia DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_ocorrencia TIME,
    local VARCHAR(120),
    descricao TEXT NOT NULL,
    testemunhas TEXT,
    anexos JSONB DEFAULT '[]'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'registada'
        CHECK (status IN ('registada','em_analise','resolvida','arquivada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 3. Sanções aplicadas
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_student_sanctions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    incident_id BIGINT NOT NULL REFERENCES school_student_incidents(id) ON DELETE CASCADE,
    sanction_type_id BIGINT REFERENCES school_sanction_types(id) ON DELETE SET NULL,
    aplicado_por BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    descricao TEXT,
    cumprida BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

-- ------------------------------------------------------------
-- 4. Méritos / distinções
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_student_merits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    enrollment_id BIGINT REFERENCES school_enrollments(id) ON DELETE SET NULL,
    titulo VARCHAR(150) NOT NULL,
    descricao TEXT,
    data_merito DATE NOT NULL DEFAULT CURRENT_DATE,
    atribuido_por BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 5. Índices
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_incidents_student ON school_student_incidents(tenant_id, student_id, data_ocorrencia);
CREATE INDEX IF NOT EXISTS idx_incidents_year ON school_student_incidents(tenant_id, school_year_id, status);
CREATE INDEX IF NOT EXISTS idx_sanctions_incident ON school_student_sanctions(tenant_id, incident_id);
CREATE INDEX IF NOT EXISTS idx_merits_student ON school_student_merits(tenant_id, student_id);

-- ------------------------------------------------------------
-- 6. Seeds por omissão
-- ------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_incident_types (tenant_id, codigo, nome, gravidade, requer_encarregado)
SELECT t.id, 'atraso', 'Atraso', 'leve', FALSE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_incident_types it WHERE it.tenant_id = t.id AND it.codigo = 'atraso'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_incident_types (tenant_id, codigo, nome, gravidade, requer_encarregado)
SELECT t.id, 'falta_injustificada', 'Falta Injustificada', 'media', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_incident_types it WHERE it.tenant_id = t.id AND it.codigo = 'falta_injustificada'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_incident_types (tenant_id, codigo, nome, gravidade, requer_encarregado)
SELECT t.id, 'perturbacao_aula', 'Perturbação de Aula', 'media', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_incident_types it WHERE it.tenant_id = t.id AND it.codigo = 'perturbacao_aula'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_incident_types (tenant_id, codigo, nome, gravidade, requer_encarregado)
SELECT t.id, 'violencia', 'Violência / Bullying', 'grave', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_incident_types it WHERE it.tenant_id = t.id AND it.codigo = 'violencia'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_sanction_types (tenant_id, codigo, nome, gravidade)
SELECT t.id, 'advertencia', 'Advertência Verbal/Escrita', 'leve'
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_sanction_types st WHERE st.tenant_id = t.id AND st.codigo = 'advertencia'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_sanction_types (tenant_id, codigo, nome, gravidade)
SELECT t.id, 'suspensao', 'Suspensão', 'grave'
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_sanction_types st WHERE st.tenant_id = t.id AND st.codigo = 'suspensao'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_sanction_types (tenant_id, codigo, nome, gravidade)
SELECT t.id, 'trabalho_comunitario', 'Trabalho Comunitário', 'media'
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_sanction_types st WHERE st.tenant_id = t.id AND st.codigo = 'trabalho_comunitario'
);
    END IF;
END $$;

