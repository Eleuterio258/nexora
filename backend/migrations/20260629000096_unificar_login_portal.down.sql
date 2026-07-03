-- ============================================================
-- Migration 096 (down): Reverte unificação de login
-- ============================================================

SET search_path TO auth, public;

ALTER TABLE gestao_escolar.school_guardians
  DROP CONSTRAINT IF EXISTS fk_school_guardians_user_id;

DROP INDEX IF EXISTS gestao_escolar.idx_school_guardians_user_id;

ALTER TABLE gestao_escolar.school_guardians
  DROP COLUMN IF EXISTS user_id;

ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS users_tipo_check,
  ADD CONSTRAINT users_tipo_check
    CHECK (tipo IN ('superadmin', 'funcionario', 'aluno'));
