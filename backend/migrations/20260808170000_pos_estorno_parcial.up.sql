-- Estorno/devolução parcial: hoje só existe POST /api/pos/sales/{id}/cancelar
-- (cancela a venda inteira). Isto acrescenta devolução item-a-item, sem
-- tocar em pos_sale_payments (que tem CHECK valor > 0 — não dá para lá gravar
-- estornos como valores negativos) nem no significado de pos_sales.status.

ALTER TABLE pos.pos_sale_items
    ADD COLUMN IF NOT EXISTS quantidade_devolvida numeric(18,2) NOT NULL DEFAULT 0;

-- Cabeçalho de uma devolução parcial (pode cobrir vários itens da mesma
-- venda, numa só operação). "metodo" é o método de reembolso — determina em
-- que balde de detalhamento por método (ver detalharPagamentosSessao em
-- pos.go) o valor devolvido é subtraído no fecho de caixa.
CREATE TABLE IF NOT EXISTS pos.pos_sale_returns (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id      bigint NOT NULL,
    pos_sale_id    bigint NOT NULL REFERENCES pos.pos_sales(id) ON DELETE CASCADE,
    motivo         text NOT NULL,
    metodo         character varying(20) NOT NULL,
    valor_total    numeric(18,2) NOT NULL,
    credit_note_id bigint,
    created_by     bigint,
    created_at     timestamptz NOT NULL DEFAULT NOW(),
    CONSTRAINT pos_sale_returns_metodo_check
        CHECK (metodo IN ('numerario','transferencia','tpa','mpesa','emola','outro')),
    CONSTRAINT pos_sale_returns_valor_check CHECK (valor_total > 0)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pos_sale_returns_credit_note_fkey'
    ) THEN
        ALTER TABLE pos.pos_sale_returns
            ADD CONSTRAINT pos_sale_returns_credit_note_fkey
            FOREIGN KEY (credit_note_id) REFERENCES faturacao.credit_notes(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS pos.pos_sale_return_items (
    id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pos_sale_return_id  bigint NOT NULL REFERENCES pos.pos_sale_returns(id) ON DELETE CASCADE,
    pos_sale_item_id    bigint NOT NULL REFERENCES pos.pos_sale_items(id),
    quantidade          numeric(18,2) NOT NULL CHECK (quantidade > 0),
    valor               numeric(18,2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pos_sale_returns_sale ON pos.pos_sale_returns (pos_sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_sale_return_items_return ON pos.pos_sale_return_items (pos_sale_return_id);
