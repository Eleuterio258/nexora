DROP TABLE IF EXISTS pos.pos_sale_return_items;
DROP TABLE IF EXISTS pos.pos_sale_returns;

ALTER TABLE pos.pos_sale_items
    DROP COLUMN IF EXISTS quantidade_devolvida;
