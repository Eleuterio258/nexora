-- Reverter migration 113

ALTER TABLE rh.recibos_vencimento
  DROP COLUMN IF EXISTS pdf_url;
