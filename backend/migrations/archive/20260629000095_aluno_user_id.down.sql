-- ============================================================
-- Migration 095 (down): Remove ligação aluno-utilizador
-- ============================================================

ALTER TABLE gestao_escolar.school_students
  DROP CONSTRAINT IF EXISTS fk_school_students_user_id;

DROP INDEX IF EXISTS gestao_escolar.idx_school_students_user_id;

ALTER TABLE gestao_escolar.school_students
  DROP COLUMN IF EXISTS user_id;
