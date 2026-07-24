-- 109_drop_school_class_ano_lectivo.up.sql
-- Remove a coluna redundante ano_lectivo varchar de school_classes.
-- O ano lectivo é obtido via JOIN com school_years (school_year_id FK).
-- O repositório Go deixou de escrever este campo (migration acompanhada de mudança no class.go).

ALTER TABLE gestao_escolar.school_classes DROP COLUMN IF EXISTS ano_lectivo;
