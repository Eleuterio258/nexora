-- Reverter migration de contratação integrada Recrutamento → RH

SET search_path TO recrutamento, public;

ALTER TABLE candidaturas
  DROP CONSTRAINT IF EXISTS candidaturas_estado_check;

ALTER TABLE candidaturas
  ADD CONSTRAINT candidaturas_estado_check
  CHECK (estado IN ('recebida','em_analise','entrevista','aprovada','rejeitada'));

ALTER TABLE candidaturas
  DROP CONSTRAINT IF EXISTS fk_candidaturas_rh_funcionario;

DROP INDEX IF EXISTS idx_candidaturas_rh_funcionario_id;

ALTER TABLE candidaturas
  DROP COLUMN IF EXISTS rh_funcionario_id,
  DROP COLUMN IF EXISTS consentimento_dados,
  DROP COLUMN IF EXISTS data_consentimento;

SET search_path TO rh, public;

ALTER TABLE funcionarios
  DROP COLUMN IF EXISTS nacionalidade,
  DROP COLUMN IF EXISTS tipo_documento,
  DROP COLUMN IF EXISTS numero_documento;
