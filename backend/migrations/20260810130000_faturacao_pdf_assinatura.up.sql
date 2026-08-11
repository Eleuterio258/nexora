-- Corrige schema drift: estas 3 colunas só existiam na migração arquivada
-- migrations/archive/20260723000003_faturacao_assinatura.up.sql, nunca
-- reintroduzidas na baseline consolidada — mas internal/modules/modulo-
-- faturacao/handlers/assinatura.go já as lê (fluxo "enviar para assinatura")
-- desde que esse ficheiro foi escrito. Necessárias também para a geração de
-- PDF no backend (esta sessão).
ALTER TABLE faturacao.invoices
    ADD COLUMN IF NOT EXISTS pdf_storage_key varchar(500),
    ADD COLUMN IF NOT EXISTS ficheiro_url varchar(1000),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id bigint;

ALTER TABLE faturacao.credit_notes
    ADD COLUMN IF NOT EXISTS pdf_storage_key varchar(500),
    ADD COLUMN IF NOT EXISTS ficheiro_url varchar(1000),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id bigint;

-- Suporte a anexo (ex.: PDF de factura) nas notificações da fila genérica —
-- ver internal/background/{jobs,mailer_ses}.go.
ALTER TABLE notifications.notification_messages
    ADD COLUMN IF NOT EXISTS anexo_storage_key varchar(500),
    ADD COLUMN IF NOT EXISTS anexo_nome varchar(255);
