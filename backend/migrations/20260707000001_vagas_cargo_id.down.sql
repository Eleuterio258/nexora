SET search_path TO recrutamento, public;

ALTER TABLE vagas DROP CONSTRAINT IF EXISTS fk_vagas_cargo;
DROP INDEX IF EXISTS idx_vagas_cargo_id;
ALTER TABLE vagas DROP COLUMN IF EXISTS cargo_id;
