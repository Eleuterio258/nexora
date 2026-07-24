-- Remover campos provisórios de school_course_subjects
ALTER TABLE gestao_escolar.school_course_subjects
    DROP COLUMN IF EXISTS term_id,
    DROP COLUMN IF EXISTS tem_exame,
    DROP COLUMN IF EXISTS peso_exame;

-- Tabela de configuração por período por disciplina do currículo.
-- Uma linha por combinação (disciplina × período).
-- Ausência de linha = disciplina não é leccionada nesse período.
-- tem_exame = true  → período termina com exame.
-- peso_exame        → peso do exame na nota final do período (NULL = sem peso fixo).
CREATE TABLE IF NOT EXISTS gestao_escolar.school_course_subject_terms (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id         BIGINT NOT NULL,
    course_subject_id BIGINT NOT NULL
        REFERENCES gestao_escolar.school_course_subjects(id) ON DELETE CASCADE,
    term_id           BIGINT NOT NULL
        REFERENCES gestao_escolar.school_terms(id) ON DELETE CASCADE,
    tem_exame         BOOLEAN      NOT NULL DEFAULT false,
    peso_exame        NUMERIC(5,2)          DEFAULT NULL,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, course_subject_id, term_id)
);

CREATE INDEX IF NOT EXISTS idx_cst_course_subject
    ON gestao_escolar.school_course_subject_terms(course_subject_id);

CREATE INDEX IF NOT EXISTS idx_cst_term
    ON gestao_escolar.school_course_subject_terms(tenant_id, term_id);
