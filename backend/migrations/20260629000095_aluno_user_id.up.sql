-- ============================================================
-- Migration 095: Ligação entre aluno e utilizador
-- ============================================================
-- Adiciona user_id em gestao_escolar.school_students para permitir
-- que alunos sejam utilizadores autenticados (tipo = 'aluno').

ALTER TABLE gestao_escolar.school_students
  ADD COLUMN IF NOT EXISTS user_id BIGINT NULL
  CONSTRAINT fk_school_students_user_id
    REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_school_students_user_id
  ON gestao_escolar.school_students(user_id);
