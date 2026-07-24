-- Adiciona suporte a assinatura digital no módulo de faturação.
ALTER TABLE faturacao.invoices
    ADD COLUMN IF NOT EXISTS ficheiro_url VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;

ALTER TABLE faturacao.credit_notes
    ADD COLUMN IF NOT EXISTS ficheiro_url VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;
