-- ============================================================
-- Migration 094: Separar tipo e escopo do utilizador
-- ============================================================
-- Move o campo escopo de auth.users para auth.memberships e permite
-- tipo = 'aluno' em auth.users.

SET search_path TO auth, public;

-- 1. Adicionar escopo em memberships
ALTER TABLE auth.memberships
  ADD COLUMN IF NOT EXISTS escopo VARCHAR(20) NOT NULL DEFAULT 'erp'
  CONSTRAINT memberships_escopo_check
    CHECK (escopo IN ('erp', 'escola', 'ambos'));

-- 2. Migrar escopo de users para memberships (apenas funcionários)
UPDATE auth.memberships m
   SET escopo = COALESCE(NULLIF(u.escopo, ''), 'erp')
  FROM auth.users u
 WHERE m.user_id = u.id
   AND u.tipo = 'funcionario';

-- 3. Permitir tipo = 'aluno'
ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS users_tipo_check,
  ADD CONSTRAINT users_tipo_check
    CHECK (tipo IN ('superadmin', 'funcionario', 'aluno'));

-- 4. Remover escopo de users
ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS chk_users_escopo;

ALTER TABLE auth.users
  DROP COLUMN IF EXISTS escopo;
