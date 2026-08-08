-- Liga cada venda POS concluída à fatura fiscal gerada automaticamente para
-- ela (ver criarFaturaParaVenda em pos/handlers/faturacao.go). Nullable
-- porque vendas antigas (anteriores a esta migração) nunca tiveram fatura.

ALTER TABLE pos.pos_sales
    ADD COLUMN IF NOT EXISTS invoice_id bigint;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pos_sales_invoice_id_fkey'
    ) THEN
        ALTER TABLE pos.pos_sales
            ADD CONSTRAINT pos_sales_invoice_id_fkey
            FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_pos_sales_invoice_id
    ON pos.pos_sales (invoice_id);
