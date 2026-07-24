-- Currículo: definir se uma disciplina tem exame e qual o seu peso
ALTER TABLE gestao_escolar.school_course_subjects
    ADD COLUMN IF NOT EXISTS tem_exame  BOOLEAN      NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS peso_exame NUMERIC(5,2) DEFAULT NULL;

-- Tipos de avaliação válidos em school_grade_items
ALTER TABLE gestao_escolar.school_grade_items
    DROP CONSTRAINT IF EXISTS school_grade_items_tipo_check;

ALTER TABLE gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_tipo_check
    CHECK (tipo IN ('TESTE','TRABALHO','APRESENTACAO','EXAME','RECURSO','OUTRO'));
