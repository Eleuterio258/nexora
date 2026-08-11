ALTER TABLE compras.purchase_invoices
    DROP COLUMN IF EXISTS journal_entry_id;

DROP TABLE IF EXISTS compras.config_contabilidade;
