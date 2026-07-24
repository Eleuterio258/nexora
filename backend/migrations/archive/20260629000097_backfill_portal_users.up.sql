-- ============================================================
-- Migration 097: Backfill de utilizadores do portal
-- ============================================================
-- Cria auth.users para alunos e encarregados que já têm portal_email
-- mas ainda não têm user_id associado.
-- A senha é migrada de portal_password_hash quando existe; caso contrário,
-- o utilizador fica pendente e define a senha no primeiro acesso.

SET search_path TO auth, gestao_escolar, public;

-- 1. Backfill de alunos -------------------------------------------------------
WITH alunos AS (
    SELECT s.id AS student_id,
           s.nome,
           s.telefone,
           LOWER(s.portal_email) AS email,
           s.portal_password_hash,
           s.portal_ativo
    FROM gestao_escolar.school_students s
    WHERE s.portal_email IS NOT NULL
      AND s.portal_email <> ''
      AND s.user_id IS NULL
),
novos_users AS (
    INSERT INTO auth.users (
        nome, email, password_hash, telefone, estado, tipo
    )
    SELECT nome,
           email,
           COALESCE(portal_password_hash, ''),
           telefone,
           CASE WHEN portal_ativo THEN 'ativo' ELSE 'pendente' END,
           'aluno'
    FROM alunos
    ON CONFLICT (email) DO NOTHING
    RETURNING id, email
)
UPDATE gestao_escolar.school_students s
   SET user_id = nu.id
  FROM novos_users nu
  JOIN alunos a ON a.email = nu.email
 WHERE s.id = a.student_id;

-- 2. Backfill de encarregados -------------------------------------------------
-- Agrupa por email porque um encarregado pode estar ligado a vários educandos.
-- Usa uma tabela temporária para evitar dependências complexas entre CTEs.
CREATE TEMP TABLE tmp_guardian_emails (
    email TEXT PRIMARY KEY,
    nome VARCHAR(150),
    telefone VARCHAR(30),
    password_hash TEXT,
    portal_ativo BOOLEAN
);

INSERT INTO tmp_guardian_emails (email, nome, telefone, password_hash, portal_ativo)
SELECT DISTINCT ON (LOWER(g.portal_email))
       LOWER(g.portal_email),
       g.nome,
       g.telefone,
       g.portal_password_hash,
       g.portal_ativo
FROM gestao_escolar.school_guardians g
WHERE g.portal_email IS NOT NULL
  AND g.portal_email <> ''
  AND g.user_id IS NULL
ORDER BY LOWER(g.portal_email), g.principal DESC, g.portal_ativo DESC;

WITH novos_users AS (
    INSERT INTO auth.users (
        nome, email, password_hash, telefone, estado, tipo
    )
    SELECT nome,
           email,
           COALESCE(password_hash, ''),
           telefone,
           CASE WHEN portal_ativo THEN 'ativo' ELSE 'pendente' END,
           'encarregado'
    FROM tmp_guardian_emails
    ON CONFLICT (email) DO NOTHING
    RETURNING id, email
)
UPDATE gestao_escolar.school_guardians g
   SET user_id = nu.id
  FROM novos_users nu
 WHERE LOWER(g.portal_email) = nu.email;

DROP TABLE tmp_guardian_emails;

-- 3. Sincronizar user_id em encarregados cujo email já existia em auth.users
--    (apenas quando o tipo existente é 'encarregado').
UPDATE gestao_escolar.school_guardians g
   SET user_id = u.id
  FROM auth.users u
 WHERE LOWER(g.portal_email) = LOWER(u.email)
   AND u.tipo = 'encarregado'
   AND g.user_id IS NULL;

-- 4. Sincronizar user_id em alunos cujo email já existia em auth.users
--    (apenas quando o tipo existente é 'aluno').
UPDATE gestao_escolar.school_students s
   SET user_id = u.id
  FROM auth.users u
 WHERE LOWER(s.portal_email) = LOWER(u.email)
   AND u.tipo = 'aluno'
   AND s.user_id IS NULL;
