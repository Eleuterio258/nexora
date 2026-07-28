-- Acrescenta auth.memberships.principal, coluna que o módulo de auth já
-- assume mas que nenhuma migração criava (nem o baseline 20260724080001).
--
-- Sintoma em produção: TODOS os logins devolviam 401 "Credenciais inválidas",
-- mesmo com a password certa. A query de loginWithCredentials
-- (auth/handlers/auth.go) faz `ORDER BY m.principal DESC NULLS LAST` e
-- rebentava com 42703; o handler trata qualquer erro do QueryRow como
-- "utilizador não encontrado" (found = err == nil), logo o erro de schema
-- ficava indistinguível de password errada e não aparecia nos logs.
--
-- Mesmas queries afectadas: auth.go:178 (login), auth.go:451 e auth.go:642
-- (refresh/troca de tenant), authcode.go:418 e authcode.go:494 (login por PIN).
--
-- Semântica: qual das memberships de um utilizador multi-tenant é a usada por
-- omissão no login. Nenhum caminho de escrita em Go define esta coluna hoje,
-- por isso novas memberships ficam a false e o desempate cai no `m.id ASC`
-- que já existe a seguir no ORDER BY.

BEGIN;

ALTER TABLE auth.memberships
    ADD COLUMN IF NOT EXISTS principal boolean NOT NULL DEFAULT false;

-- Backfill: a membership activa mais antiga de cada utilizador passa a ser a
-- principal. À data desta migração nenhum utilizador tinha mais do que uma
-- membership activa, portanto isto apenas torna explícito o que já acontecia.
UPDATE auth.memberships m
   SET principal = true
 WHERE m.id = (
        SELECT m2.id
          FROM auth.memberships m2
         WHERE m2.user_id = m.user_id
           AND m2.ativo
         ORDER BY m2.id
         LIMIT 1
      );

-- Garante o invariante que o ORDER BY assume: no máximo uma principal por
-- utilizador.
CREATE UNIQUE INDEX IF NOT EXISTS uq_memberships_principal_por_user
    ON auth.memberships (user_id)
    WHERE principal;

COMMENT ON COLUMN auth.memberships.principal IS
    'Membership usada por omissão no login de um utilizador com várias '
    'memberships. Lida em ORDER BY nas queries de auth; ver 20260728000003.';

COMMIT;
