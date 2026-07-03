SET search_path TO produtos, public;

ALTER TABLE product_categories
    ADD COLUMN IF NOT EXISTS parent_id BIGINT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'fk_product_categories_parent'
           AND conrelid = 'produtos.product_categories'::regclass
    ) THEN
        ALTER TABLE product_categories
            ADD CONSTRAINT fk_product_categories_parent
            FOREIGN KEY (parent_id) REFERENCES product_categories(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_product_categories_parent
    ON product_categories (tenant_id, parent_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product_sku
    ON product_variants (product_id, sku);
CREATE INDEX IF NOT EXISTS idx_product_prices_product_active
    ON product_prices (product_id, ativo);
CREATE INDEX IF NOT EXISTS idx_product_discounts_product_active
    ON product_discounts (product_id, ativo);
CREATE INDEX IF NOT EXISTS idx_stock_items_product_warehouse
    ON stock.stock_items (tenant_id, product_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_date
    ON stock.stock_movements (tenant_id, movement_date);
