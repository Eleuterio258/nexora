-- ============================================================
-- Migration 094 (down): Reverte separação de tipo e escopo
-- ============================================================

SET search_path TO auth, public;

-- 1. Recriar coluna escopo em users
ALTER TABLE auth.users
  ADD COLUMN IF NOT EXISTS escopo VARCHAR(20) NOT NULL DEFAULT 'erp'
  CONSTRAINT chk_users_escopo
    CHECK (escopo IN ('erp', 'escola', 'ambos'));

-- 2. Migrar escopo de memberships para users (escolhe o escopo da membership ativa)
UPDATE auth.users u
   SET escopo = COALESCE(
     (SELECT m.escopo
        FROM auth.memberships m
       WHERE m.user_id = u.id
         AND m.ativo = true
       LIMIT 1),
     'erp'
   );

-- 3. Remover escopo de memberships
ALTER TABLE auth.memberships
  DROP CONSTRAINT IF EXISTS memberships_escopo_check;

ALTER TABLE auth.memberships
  DROP COLUMN IF EXISTS escopo;

-- 4. Remover tipo 'aluno'
ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS users_tipo_check,
  ADD CONSTRAINT users_tipo_check
    CHECK (tipo IN ('superadmin', 'funcionario'));
