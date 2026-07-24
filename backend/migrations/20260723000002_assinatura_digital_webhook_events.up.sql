-- Tabela de eventos de webhook de providers de assinatura.
-- Permite idempotência (provider + event_id únicos) e rastreabilidade.
CREATE TABLE IF NOT EXISTS assinatura_digital.webhook_events (
    id          BIGSERIAL PRIMARY KEY,
    provider    VARCHAR(50) NOT NULL,
    event_id    VARCHAR(255) NOT NULL,
    event_type  VARCHAR(100) NOT NULL,
    payload     JSONB NOT NULL,
    processado  BOOLEAN DEFAULT FALSE,
    erro        TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provider, event_id)
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_provider_event_id ON assinatura_digital.webhook_events(provider, event_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processado ON assinatura_digital.webhook_events(processado);
