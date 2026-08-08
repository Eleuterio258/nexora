DROP INDEX IF EXISTS pos.idx_pos_sales_tenant_client_reference;

ALTER TABLE pos.pos_sales
    DROP COLUMN IF EXISTS client_reference;
