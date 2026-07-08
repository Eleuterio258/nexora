-- Adicionar term_id a school_course_subjects:
-- NULL = disciplina leccionada durante todo o ano
-- SET  = disciplina leccionada apenas nesse período
ALTER TABLE gestao_escolar.school_course_subjects
    ADD COLUMN IF NOT EXISTS term_id BIGINT
        REFERENCES gestao_escolar.school_terms(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_course_subjects_term
    ON gestao_escolar.school_course_subjects(tenant_id, term_id);

-- Corrigir componente: apenas valores semânticos válidos
ALTER TABLE gestao_escolar.school_course_subjects
    DROP CONSTRAINT IF EXISTS school_course_subjects_componente_check;

ALTER TABLE gestao_escolar.school_course_subjects
    ADD CONSTRAINT school_course_subjects_componente_check
    CHECK (componente IN ('teorica','pratica','laboratorial','anual','outro'));
