-- Fecha o ciclo assíncrono do pagamento móvel (M-Pesa/e-Mola via Nexora-Pay):
-- até agora só existia StatusPagamento, que faz POLL ao gateway — nada no
-- backend ficava a saber, por iniciativa própria, quando um pagamento
-- confirmava. Esta tabela é o destino do novo webhook (ver
-- pos.WebhookPagamento em pagamentos.go): guarda a confirmação assim que o
-- gateway a envia, e StatusPagamento passa a consultá-la primeiro (mais
-- rápido, resiliente a lentidão do gateway), só voltando a perguntar ao
-- Nexora-Pay se ainda não houver confirmação local.

CREATE TABLE IF NOT EXISTS pos.pos_payment_confirmations (
    id                    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id             bigint NOT NULL,
    gateway_txn_id        character varying(100) NOT NULL,
    third_party_reference character varying(100),
    provider              character varying(20),
    status                character varying(30) NOT NULL,
    transaction_status    character varying(30),
    payload               jsonb,
    confirmed_at          timestamptz NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, gateway_txn_id)
);

CREATE INDEX IF NOT EXISTS idx_pos_payment_confirmations_gateway_txn
    ON pos.pos_payment_confirmations (gateway_txn_id);
