-- ============================================================
-- Migration: Cargo a contratar definido na vaga
-- ============================================================
-- O recrutador escolhia o cargo manualmente no momento da
-- contratação (ad-hoc, podendo variar entre contratações da mesma
-- vaga). Agora o cargo faz parte da definição da vaga e é aplicado
-- automaticamente ao funcionário criado ao contratar.
-- ============================================================

SET search_path TO recrutamento, public;

ALTER TABLE vagas
  ADD COLUMN IF NOT EXISTS cargo_id BIGINT;

ALTER TABLE vagas
  ADD CONSTRAINT fk_vagas_cargo
  FOREIGN KEY (cargo_id) REFERENCES rh.cargos(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_vagas_cargo_id
  ON vagas (cargo_id);
