ALTER TABLE faturacao.invoices
    DROP CONSTRAINT IF EXISTS invoices_tipo_check,
    ADD CONSTRAINT invoices_tipo_check
        CHECK (tipo = ANY (ARRAY['normal', 'proforma']::varchar[]));

ALTER TABLE faturacao.invoice_series
    DROP CONSTRAINT IF EXISTS invoice_series_tipo_check,
    ADD CONSTRAINT invoice_series_tipo_check
        CHECK (tipo = ANY (ARRAY['ORC', 'ENC', 'GR', 'FT', 'NC', 'RB', 'VD']::varchar[]));
