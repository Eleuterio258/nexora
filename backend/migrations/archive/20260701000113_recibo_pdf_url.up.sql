-- Migration 113: cache do PDF gerado do recibo de vencimento (guardado no MinIO)

ALTER TABLE rh.recibos_vencimento
  ADD COLUMN IF NOT EXISTS pdf_url TEXT;
