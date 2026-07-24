-- Reverter migration 112

SET search_path TO auth, recrutamento, public;

ALTER TABLE recrutamento.candidatos
  ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

DROP INDEX IF EXISTS recrutamento.idx_candidatos_user_id;

ALTER TABLE recrutamento.candidatos
  DROP CONSTRAINT IF EXISTS fk_candidatos_user_id;
ALTER TABLE recrutamento.candidatos
  DROP COLUMN IF EXISTS user_id;

ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS users_tipo_check;
ALTER TABLE auth.users
  ADD CONSTRAINT users_tipo_check
  CHECK (tipo IN ('superadmin', 'funcionario', 'aluno', 'encarregado'));
