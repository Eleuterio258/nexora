-- ============================================================
-- Migration 111: Escopo portal_professor em memberships
-- tipo permanece 'funcionario'; escopo='portal_professor' identifica professores
-- ============================================================

SET search_path TO auth, gestao_escolar, public;

-- 1. Alargar constraint de memberships.escopo
ALTER TABLE auth.memberships
  DROP CONSTRAINT IF EXISTS memberships_escopo_check;
ALTER TABLE auth.memberships
  ADD CONSTRAINT memberships_escopo_check
  CHECK (escopo IN ('erp', 'escola', 'portal_aluno', 'portal_encarregado', 'portal_professor'));

-- 2. Mudar escopo dos professores: escola → portal_professor
--    (identificados pelo vínculo em school_teachers)
UPDATE auth.memberships m
   SET escopo     = 'portal_professor',
       updated_at = NOW()
  FROM gestao_escolar.school_teachers t
  JOIN auth.users u ON u.id = t.user_id
 WHERE m.user_id = u.id
   AND m.escopo  = 'escola';

-- 3. tipo já voltou a ser 'funcionario' — restaurar constraint sem 'professor'
ALTER TABLE auth.users
  DROP CONSTRAINT IF EXISTS users_tipo_check;
ALTER TABLE auth.users
  ADD CONSTRAINT users_tipo_check
  CHECK (tipo IN ('superadmin', 'funcionario', 'aluno', 'encarregado'));

DROP INDEX IF EXISTS auth.idx_users_tipo_professor;
