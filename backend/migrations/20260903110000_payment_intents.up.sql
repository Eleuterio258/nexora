CREATE TABLE integration.payment_intents (
    id VARCHAR(36) PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    source_module VARCHAR(20) NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    idempotency_key VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    provider VARCHAR(20),
    msisdn VARCHAR(20),
    amount NUMERIC(18,2) NOT NULL,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    gateway_transaction_id VARCHAR(100),
    third_party_reference VARCHAR(100),
    request_payload JSONB,
    response_payload JSONB,
    erro TEXT,
    attempts INT NOT NULL DEFAULT 0,
    available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_at TIMESTAMPTZ,
    locked_by VARCHAR(100),
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    CONSTRAINT uq_payment_intents_idempotency_key UNIQUE (idempotency_key),
    CONSTRAINT ck_payment_intents_status CHECK (status IN ('pending','processing','confirmed','failed','unknown'))
);

-- So um intent activo por (tenant, modulo, referencia) de cada vez: um 2o
-- pedido enquanto o 1o ainda esta em curso bate nesta constraint em vez de
-- chamar o gateway outra vez (so aplicavel ao fluxo escolar, que tem
-- reference_id estavel = school_fees.id; o POS nao tem venda gravada antes
-- do pagamento, ver docs/analise-transactional-outbox-backends.md secao 12).
CREATE UNIQUE INDEX uq_payment_intents_active_reference
    ON integration.payment_intents (tenant_id, source_module, reference_type, reference_id)
    WHERE status IN ('pending','processing','unknown') AND reference_id IS NOT NULL;

CREATE INDEX idx_payment_intents_dispatch
    ON integration.payment_intents (available_at, created_at)
    WHERE status IN ('pending','processing','unknown');

CREATE INDEX idx_payment_intents_gateway_txn
    ON integration.payment_intents (gateway_transaction_id)
    WHERE gateway_transaction_id IS NOT NULL;
