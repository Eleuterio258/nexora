-- ============================================================
-- Down migration 088: remove a coluna escopo de auth.users
-- ============================================================

SET search_path TO auth, public;

ALTER TABLE auth.users
    DROP CONSTRAINT IF EXISTS chk_users_escopo;

ALTER TABLE auth.users
    DROP COLUMN IF EXISTS escopo;
