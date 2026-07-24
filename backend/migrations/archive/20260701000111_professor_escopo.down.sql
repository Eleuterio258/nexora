-- Reverter migration 111

SET search_path TO auth, gestao_escolar, public;

UPDATE auth.memberships m
   SET escopo = 'escola', updated_at = NOW()
  FROM gestao_escolar.school_teachers t
  JOIN auth.users u ON u.id = t.user_id
 WHERE m.user_id = u.id
   AND m.escopo  = 'portal_professor';

ALTER TABLE auth.memberships
  DROP CONSTRAINT IF EXISTS memberships_escopo_check;
ALTER TABLE auth.memberships
  ADD CONSTRAINT memberships_escopo_check
  CHECK (escopo IN ('erp', 'escola'));
