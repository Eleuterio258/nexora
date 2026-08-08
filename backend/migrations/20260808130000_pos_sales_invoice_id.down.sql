ALTER TABLE pos.pos_sales
    DROP CONSTRAINT IF EXISTS pos_sales_invoice_id_fkey;

DROP INDEX IF EXISTS pos.idx_pos_sales_invoice_id;

ALTER TABLE pos.pos_sales
    DROP COLUMN IF EXISTS invoice_id;
