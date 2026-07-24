-- Tabela de tarefas escolares (professor -> turma/alunos)

CREATE TABLE IF NOT EXISTS gestao_escolar.school_tasks (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    school_year_id  BIGINT REFERENCES gestao_escolar.school_years(id) ON DELETE SET NULL,
    class_id        BIGINT NOT NULL REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE,
    subject_id      BIGINT REFERENCES gestao_escolar.school_subjects(id) ON DELETE SET NULL,
    teacher_id      BIGINT NOT NULL REFERENCES gestao_escolar.school_teachers(id) ON DELETE CASCADE,
    titulo          VARCHAR(180) NOT NULL,
    descricao       TEXT,
    tipo            VARCHAR(30) NOT NULL DEFAULT 'tarefa',
    data_inicio     DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim        DATE NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'activa'
        CHECK (status IN ('activa','concluida','cancelada')),
    created_by      BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_school_tasks_class
    ON gestao_escolar.school_tasks(tenant_id, class_id, status);
CREATE INDEX IF NOT EXISTS idx_school_tasks_teacher
    ON gestao_escolar.school_tasks(tenant_id, teacher_id, status);
CREATE INDEX IF NOT EXISTS idx_school_tasks_dates
    ON gestao_escolar.school_tasks(tenant_id, data_fim);
