-- Item 4 do plano-mudancas-backend-paycore-mobile.md: a app ja envia
-- EstornoRequest{reason} ao cancelar uma venda, mas o backend ainda nao
-- guardava o motivo.
ALTER TABLE pos.pos_sales
    ADD COLUMN motivo_cancelamento TEXT;
