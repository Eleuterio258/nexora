ALTER TABLE auth.memberships
  DROP CONSTRAINT IF EXISTS memberships_escopo_check;

ALTER TABLE auth.memberships
  ADD CONSTRAINT memberships_escopo_check
  CHECK (escopo IN ('erp', 'escola', 'ambos'));
