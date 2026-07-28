-- Remove auth.memberships.principal criada por
-- 20260728000003_memberships_principal.up.sql.
-- ATENÇÃO: reverter isto volta a partir todos os logins enquanto o código Go
-- mantiver o `ORDER BY m.principal` em auth/handlers/{auth,authcode}.go.
BEGIN;

DROP INDEX IF EXISTS auth.uq_memberships_principal_por_user;

ALTER TABLE auth.memberships
    DROP COLUMN IF EXISTS principal;

COMMIT;
