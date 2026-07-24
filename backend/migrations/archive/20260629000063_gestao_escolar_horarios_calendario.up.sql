-- ============================================================
-- Migration 063: Horários e Calendário Escolar
-- ============================================================

SET search_path TO gestao_escolar, public;

-- ------------------------------------------------------------
-- 1. Horários base (slots do dia)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_time_slots (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(60),
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    ordem INTEGER NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo),
    CHECK (hora_fim > hora_inicio)
);

-- ------------------------------------------------------------
-- 2. Horário de aulas (timetable)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_timetable_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
    class_id BIGINT NOT NULL REFERENCES school_classes(id) ON DELETE CASCADE,
    subject_id BIGINT NOT NULL REFERENCES school_subjects(id) ON DELETE CASCADE,
    teacher_id BIGINT NOT NULL REFERENCES school_teachers(id) ON DELETE RESTRICT,
    time_slot_id BIGINT NOT NULL REFERENCES school_time_slots(id) ON DELETE RESTRICT,
    dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
    sala VARCHAR(50),
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, school_year_id, class_id, dia_semana, time_slot_id),
    CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

-- ------------------------------------------------------------
-- 3. Calendário escolar e tipos de evento
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_calendar_event_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    cor VARCHAR(7) DEFAULT '#3B82F6',
    impacto_frequencia VARCHAR(20) NOT NULL DEFAULT 'nenhum'
        CHECK (impacto_frequencia IN ('nenhum','nao_contabiliza','marcar_ausencia')),
    dia_todo BOOLEAN NOT NULL DEFAULT TRUE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_calendar_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
    event_type_id BIGINT REFERENCES school_calendar_event_types(id) ON DELETE SET NULL,
    titulo VARCHAR(180) NOT NULL,
    descricao TEXT,
    data_inicio DATE NOT NULL,
    data_fim DATE,
    hora_inicio TIME,
    hora_fim TIME,
    dia_todo BOOLEAN NOT NULL DEFAULT TRUE,
    publico_alvo VARCHAR(30) DEFAULT 'todos' CHECK (publico_alvo IN ('todos','alunos','professores','turma','curso')),
    publico_alvo_id BIGINT,
    created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    CHECK (hora_fim IS NULL OR hora_inicio IS NULL OR hora_fim > hora_inicio)
);

-- ------------------------------------------------------------
-- 4. Índices
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_timetable_class ON school_timetable_entries(tenant_id, class_id, activo);
CREATE INDEX IF NOT EXISTS idx_timetable_teacher ON school_timetable_entries(tenant_id, teacher_id, activo);
CREATE INDEX IF NOT EXISTS idx_timetable_room ON school_timetable_entries(tenant_id, sala, dia_semana, time_slot_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_year ON school_calendar_events(tenant_id, school_year_id, data_inicio);

-- ------------------------------------------------------------
-- 5. Seeds por omissão
-- ------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_calendar_event_types (tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo)
SELECT t.id, 'feriado', 'Feriado', '#EF4444', 'nao_contabiliza', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_calendar_event_types et WHERE et.tenant_id = t.id AND et.codigo = 'feriado'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_calendar_event_types (tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo)
SELECT t.id, 'exame', 'Exame', '#F59E0B', 'nenhum', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_calendar_event_types et WHERE et.tenant_id = t.id AND et.codigo = 'exame'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_calendar_event_types (tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo)
SELECT t.id, 'reuniao', 'Reunião', '#10B981', 'nenhum', FALSE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_calendar_event_types et WHERE et.tenant_id = t.id AND et.codigo = 'reuniao'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_calendar_event_types (tenant_id, codigo, nome, cor, impacto_frequencia, dia_todo)
SELECT t.id, 'evento', 'Evento Escolar', '#3B82F6', 'nenhum', TRUE
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_calendar_event_types et WHERE et.tenant_id = t.id AND et.codigo = 'evento'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
SELECT t.id, 'm1', '1ª Aula', '07:30', '08:15', 1
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_time_slots s WHERE s.tenant_id = t.id AND s.codigo = 'm1'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
SELECT t.id, 'm2', '2ª Aula', '08:20', '09:05', 2
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_time_slots s WHERE s.tenant_id = t.id AND s.codigo = 'm2'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
SELECT t.id, 'm3', '3ª Aula', '09:10', '09:55', 3
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_time_slots s WHERE s.tenant_id = t.id AND s.codigo = 'm3'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
SELECT t.id, 'm4', '4ª Aula', '10:15', '11:00', 4
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_time_slots s WHERE s.tenant_id = t.id AND s.codigo = 'm4'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
SELECT t.id, 'm5', '5ª Aula', '11:05', '11:50', 5
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_time_slots s WHERE s.tenant_id = t.id AND s.codigo = 'm5'
);
    END IF;
END $$;


DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'saas' AND table_name = 'tenants') THEN
        INSERT INTO school_time_slots (tenant_id, codigo, nome, hora_inicio, hora_fim, ordem)
SELECT t.id, 'm6', '6ª Aula', '12:00', '12:45', 6
FROM saas.tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM school_time_slots s WHERE s.tenant_id = t.id AND s.codigo = 'm6'
);
    END IF;
END $$;

