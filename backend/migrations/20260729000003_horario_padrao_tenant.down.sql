BEGIN;
DROP INDEX IF EXISTS rh.uq_horarios_trabalho_padrao_por_tenant;
ALTER TABLE rh.horarios_trabalho DROP COLUMN IF EXISTS padrao;
COMMIT;
