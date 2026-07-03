-- ============================================================
-- Migration 088: Adicionar flag escopo ao utilizador
-- ============================================================
-- Define explicitamente se uma conta acede só ao ERP, só ao
-- Painel Escolar, ou a ambos. Valor por defeito 'erp' mantém
-- o comportamento actual das contas existentes.
-- ============================================================

SET search_path TO auth, public;

-- Adiciona a coluna se ainda não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'auth'
          AND table_name   = 'users'
          AND column_name  = 'escopo'
    ) THEN
        ALTER TABLE auth.users
            ADD COLUMN escopo VARCHAR(20) NOT NULL DEFAULT 'erp';
    END IF;
END $$;

-- Garante o CHECK constraint
ALTER TABLE auth.users
    DROP CONSTRAINT IF EXISTS chk_users_escopo;

ALTER TABLE auth.users
    ADD CONSTRAINT chk_users_escopo
    CHECK (escopo IN ('erp', 'escola', 'ambos'));

-- Actualiza utilizadores sem valor explícito (segurança extra)
UPDATE auth.users
   SET escopo = 'erp'
 WHERE escopo IS NULL OR escopo = '';
