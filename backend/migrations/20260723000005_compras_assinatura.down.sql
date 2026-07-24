ALTER TABLE compras.purchase_orders
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;
