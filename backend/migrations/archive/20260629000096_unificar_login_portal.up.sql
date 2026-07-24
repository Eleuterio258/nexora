-- ============================================================
-- Migration 096: Unificar login dos portais na tabela auth.users
-- ============================================================
-- Adiciona user_id em school_guardians e permite tipo = 'encarregado'.
-- O login dos portais passa a autenticar via auth.users (email/password_hash).

SET search_path TO auth, public;

-- 1. Adicionar user_id em encarregados
ALTER TABLE gestao_escolar.school_guardians
  ADD COLUMN IF NOT EXISTS user_id BIGINT NULL
  CONSTRAINT fk_school_guardians_user_id
    REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_school_guardians_user_id
  ON gestao_escolar.school_guardians(user_id);

-- 2. Permitir encarregado como tipo de utilizador
ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS users_tipo_check,
  ADD CONSTRAINT users_tipo_check
    CHECK (tipo IN ('superadmin', 'funcionario', 'aluno', 'encarregado'));
