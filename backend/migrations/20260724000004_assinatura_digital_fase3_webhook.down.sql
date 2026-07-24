DROP INDEX IF EXISTS assinatura_digital.uq_webhook_events_provider_nonce;

ALTER TABLE assinatura_digital.webhook_events
    DROP COLUMN IF EXISTS tenant_id,
    DROP COLUMN IF EXISTS nonce;
