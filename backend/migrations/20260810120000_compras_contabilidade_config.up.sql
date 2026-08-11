-- Ligação Compras → Contabilidade: configuração por tenant de qual diário e
-- quais contas usar ao gerar o lançamento contabilístico automático quando
-- uma factura de fornecedor é emitida (AdicionarItemFacturaCompra, que é o
-- que transiciona compras.purchase_invoices de 'rascunho' para 'emitida').
-- Sem registo activo, a factura de compra continua a funcionar normalmente,
-- apenas sem lançamento contábil — mesmo padrão de faturacao.config_contabilidade.
CREATE TABLE IF NOT EXISTS compras.config_contabilidade (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id bigint NOT NULL,
    accounting_journal_id bigint NOT NULL,
    conta_fornecedores_id bigint NOT NULL,
    conta_despesa_id bigint NOT NULL,
    conta_iva_id bigint,
    ativo boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_compras_config_contabilidade_tenant UNIQUE (tenant_id)
);

-- Rastreio do lançamento gerado para cada factura de compra, para
-- idempotência: só é gerado quando a factura sai de 'rascunho' pela primeira
-- vez (primeiro item adicionado). Itens adicionados depois disso não
-- actualizam o lançamento já criado — limitação conhecida, ver
-- lacunasde10082026.md item 5.
ALTER TABLE compras.purchase_invoices
    ADD COLUMN IF NOT EXISTS journal_entry_id bigint;
