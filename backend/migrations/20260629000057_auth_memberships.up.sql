-- Migration 057: Separar tenant_id e cargo_id de auth.users para auth.memberships
--
-- Motivo: auth.users passou a ser uma tabela de identidade global.
-- A associação utilizador ↔ tenant (e o cargo dentro desse tenant) é gerida
-- por auth.memberships, permitindo que superadmins existam sem tenant.
-- Nesta versão: UNIQUE(user_id) garante que cada utilizador pertence a no máximo 1 tenant.

-- 1. Tornar tenant_id nullable (para superadmins sem tenant)
ALTER TABLE auth.users ALTER COLUMN tenant_id DROP NOT NULL;

-- 2. Limpar tenant de superadmins
UPDATE auth.users SET tenant_id = NULL WHERE tipo = 'superadmin';

-- 3. Criar tabela de memberships
CREATE TABLE auth.memberships (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id  BIGINT NOT NULL REFERENCES saas.tenants(id) ON DELETE CASCADE,
  cargo_id   BIGINT REFERENCES auth.cargos(id) ON DELETE SET NULL,
  ativo      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id)
);

CREATE INDEX idx_memberships_tenant_id ON auth.memberships(tenant_id);

-- 4. Migrar dados existentes
INSERT INTO auth.memberships (user_id, tenant_id, cargo_id)
SELECT id, tenant_id, cargo_id
FROM auth.users
WHERE tenant_id IS NOT NULL;

-- 5. Remover colunas de auth.users
ALTER TABLE auth.users DROP COLUMN tenant_id;
ALTER TABLE auth.users DROP COLUMN cargo_id;
