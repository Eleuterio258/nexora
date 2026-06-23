SET search_path TO clientes, public;

ALTER TABLE customer_groups
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE customers
    ADD COLUMN IF NOT EXISTS bloqueio_motivo TEXT,
    ADD COLUMN IF NOT EXISTS bloqueado_em TIMESTAMPTZ;

ALTER TABLE customer_credit_limits
    ADD COLUMN IF NOT EXISTS motivo TEXT,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT;

ALTER TABLE customer_payments
    ADD COLUMN IF NOT EXISTS created_by BIGINT;

ALTER TABLE customer_history
    ADD COLUMN IF NOT EXISTS created_by BIGINT;

ALTER TABLE customer_discounts
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_customers_tenant_estado
    ON customers (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_customer_payments_tenant_pago_em
    ON customer_payments (tenant_id, pago_em DESC);
CREATE INDEX IF NOT EXISTS idx_customer_history_customer_created
    ON customer_history (customer_id, created_at DESC);
