BEGIN;

ALTER TABLE rh.presencas
    DROP COLUMN IF EXISTS justificado;

COMMIT;
