-- Migration de catch-up: coluna `tipo` de rh.presencas
--
-- A coluna `tipo` já existia na BD real de produção (aplicada fora do
-- tracking do golang-migrate, provavelmente via script manual), mas nenhuma
-- migration versionada a criava — quem reconstruísse a BD do zero a partir de
-- `migrate up` não a teria. Descoberto e documentado em
-- assiduidade_system_backend/CONTRATO-INTEGRACAO-ERP.md, secção 3, durante a
-- integração com o FaceClock (2026-07-11). Esta migration só documenta o
-- estado real — não deve alterar nada em bases já correctas.

SET search_path TO rh, public;

ALTER TABLE presencas
  ADD COLUMN IF NOT EXISTS tipo VARCHAR(20) DEFAULT 'presente';

ALTER TABLE presencas
  DROP CONSTRAINT IF EXISTS presencas_tipo_check;

ALTER TABLE presencas
  ADD CONSTRAINT presencas_tipo_check
  CHECK (tipo IN ('presente', 'atraso', 'falta', 'saida_antecipada'));
