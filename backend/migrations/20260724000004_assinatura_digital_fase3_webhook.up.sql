-- Assinatura digital — Fase 3 (webhook):
--   * nonce passa a ser usado (não só recebido e ignorado): impede reutilizar
--     um nonce já visto para o mesmo provider com um event_id diferente
--     (defesa adicional contra replay, complementar à unicidade de event_id);
--   * tenant_id passa a ser guardado por evento para permitir auditoria e
--     validação de vínculo tenant/documento/signatário no processamento.
ALTER TABLE assinatura_digital.webhook_events
    ADD COLUMN IF NOT EXISTS nonce TEXT,
    ADD COLUMN IF NOT EXISTS tenant_id BIGINT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_webhook_events_provider_nonce
    ON assinatura_digital.webhook_events(provider, nonce)
    WHERE nonce IS NOT NULL AND nonce <> '';
