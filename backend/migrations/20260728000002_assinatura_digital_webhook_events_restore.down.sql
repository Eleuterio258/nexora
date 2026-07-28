-- Remove assinatura_digital.webhook_events reposta por
-- 20260728000002_assinatura_digital_webhook_events_restore.up.sql.
-- Arrasta consigo as colunas nonce/tenant_id e o índice único parcial que a
-- 20260724000004_assinatura_digital_fase3_webhook acrescenta por cima.
DROP INDEX IF EXISTS assinatura_digital.uq_webhook_events_provider_nonce;
DROP INDEX IF EXISTS assinatura_digital.idx_webhook_events_processado;
DROP INDEX IF EXISTS assinatura_digital.idx_webhook_events_provider_event_id;
DROP TABLE IF EXISTS assinatura_digital.webhook_events;
