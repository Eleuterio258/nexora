-- Idempotência para vendas criadas offline (PayCore Mobile): o app gera um
-- UUID local por transação (TransacaoPDVEntity.id) antes de tentar sincronizar
-- com o servidor. Se a sync for repetida (ex.: a app perdeu a resposta HTTP
-- mas o pedido já tinha sido processado), reenviar o mesmo client_reference
-- devolve a venda já criada em vez de duplicar a venda e o movimento de stock.
--
-- Único por tenant (não globalmente) porque o UUID é gerado localmente no
-- terminal, sem coordenação entre tenants.

ALTER TABLE pos.pos_sales
    ADD COLUMN IF NOT EXISTS client_reference character varying(64);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pos_sales_tenant_client_reference
    ON pos.pos_sales (tenant_id, client_reference)
    WHERE client_reference IS NOT NULL;
