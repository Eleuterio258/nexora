ALTER TABLE faturacao.invoices
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;

ALTER TABLE faturacao.credit_notes
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;
