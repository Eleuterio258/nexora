-- Alinhamento com o protótipo phc (Fatura-Recibo/Venda a Dinheiro): permite
-- faturas "pagas na emissão" sem passar por um recibo separado. VD já
-- constava do CHECK de invoice_series.tipo mas nunca chegou a ser usada
-- pelo handler; FR é nova. invoices.tipo passa a aceitar os dois, ao lado
-- de normal/proforma, para o handler decidir o comportamento de emissão.

ALTER TABLE faturacao.invoice_series
    DROP CONSTRAINT IF EXISTS invoice_series_tipo_check,
    ADD CONSTRAINT invoice_series_tipo_check
        CHECK (tipo = ANY (ARRAY['ORC', 'ENC', 'GR', 'FT', 'NC', 'RB', 'VD', 'FR']::varchar[]));

ALTER TABLE faturacao.invoices
    DROP CONSTRAINT IF EXISTS invoices_tipo_check,
    ADD CONSTRAINT invoices_tipo_check
        CHECK (tipo = ANY (ARRAY['normal', 'proforma', 'FR', 'VD']::varchar[]));
