SET search_path TO rh, public;

ALTER TABLE presencas DROP CONSTRAINT IF EXISTS presencas_tipo_check;
ALTER TABLE presencas DROP COLUMN IF EXISTS tipo;
