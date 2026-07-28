-- Repõe assinatura_digital.webhook_events, deixada de fora do rebaseline de
-- migrações de 2026-07-24.
--
-- Mesmo caso do schema `hardware` (20260725140001_hardware_restore) e da
-- rh.qr_tokens (20260725150000_rh_qr_tokens_restore): o baseline
-- 20260724080001_baseline_schema.up.sql não inclui esta tabela, e a migração
-- original ficou em archive/20260723000002_assinatura_digital_webhook_events
-- sem nunca ser reaplicada.
--
-- Sem esta tabela o endpoint POST /api/assinatura-digital/webhooks/{provider}
-- (montado em internal/router/router.go) rebenta com 42P01 em qualquer
-- chamada: reservarWebhookEvent faz INSERT ... INTO webhook_events
-- (assinatura-digital/handlers/webhooks.go). O ON CONFLICT (provider,
-- event_id) do handler depende da UNIQUE(provider, event_id) abaixo.
--
-- ORDEM: tem de correr ANTES de 20260724000004_assinatura_digital_fase3_webhook,
-- que faz ALTER TABLE nesta tabela para acrescentar `nonce`/`tenant_id`.
-- Atenção: a 20260724000004 tem versão MENOR do que esta, porque a lacuna só
-- foi detectada agora — por ordem de versão ela vem primeiro e volta a falhar.
-- Aplicar por ordem explícita (as migrações desta BD são corridas à mão).
--
-- Conteúdo idêntico ao da migração arquivada. As colunas nonce/tenant_id NÃO
-- são criadas aqui de propósito — é a 20260724000004 que as acrescenta, para
-- manter as duas independentes e reversíveis em separado.

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
