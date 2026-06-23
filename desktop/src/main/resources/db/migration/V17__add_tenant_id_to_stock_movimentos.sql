-- Add tenant_id column to stock_movimentos (was missing from V9 original schema)
ALTER TABLE stock_movimentos ADD COLUMN tenant_id INTEGER REFERENCES tenants(id);
