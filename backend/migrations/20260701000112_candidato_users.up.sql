-- ============================================================
-- Migration 112: Login único de candidatos via auth.users
-- ============================================================
-- Permite tipo = 'candidato' em auth.users e liga recrutamento.candidatos
-- à identidade global. A password passa a viver só em auth.users;
-- recrutamento.candidatos deixa de ter password_hash própria.

SET search_path TO auth, recrutamento, public;

-- 1. Permitir tipo = 'candidato'
ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS users_tipo_check;
ALTER TABLE auth.users
  ADD CONSTRAINT users_tipo_check
  CHECK (tipo IN ('superadmin', 'funcionario', 'aluno', 'encarregado', 'candidato'));

-- 2. Ligar candidatos à identidade global (não único: a mesma pessoa pode
--    candidatar-se em vários tenants, cada um com a sua linha em candidatos)
ALTER TABLE recrutamento.candidatos
  ADD COLUMN IF NOT EXISTS user_id BIGINT NULL
  CONSTRAINT fk_candidatos_user_id REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_candidatos_user_id ON recrutamento.candidatos (user_id);

-- 3. Password deixa de viver em candidatos (tabela está vazia em produção)
ALTER TABLE recrutamento.candidatos
  DROP COLUMN IF EXISTS password_hash;
