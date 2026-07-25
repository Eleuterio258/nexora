-- Repõe rh.qr_tokens, deixada de fora do rebaseline de migrações de 2026-07-24.
--
-- Mesmo caso do schema `hardware` (ver 20260725140001_hardware_restore): o
-- baseline 20260724080001_baseline_schema.up.sql não inclui esta tabela, e a
-- migração original ficou em archive/20260712000126_rh_qr_tokens.up.sql sem
-- nunca ser reaplicada.
--
-- Tem de correr ANTES de 20260725150001_qr_tokens_funcionario_id, que faz
-- ALTER TABLE rh.qr_tokens e falhava com "relation rh.qr_tokens does not
-- exist", deixando o schema_migrations em estado dirty.
--
-- Sem esta tabela, os endpoints de QR de assiduidade
-- (recursos-humanos/handlers/assiduidade_qr.go) não funcionam: gerar QR do
-- gestor, QR pessoal do colaborador e validação da leitura.
--
-- Conteúdo idêntico ao da migração arquivada. A coluna funcionario_id NÃO é
-- criada aqui de propósito — é a migração seguinte que a acrescenta, para
-- manter as duas independentes e reversíveis em separado.

SET search_path TO rh, public;

CREATE TABLE IF NOT EXISTS qr_tokens (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    token       VARCHAR(80) NOT NULL,
    location_id VARCHAR(100),
    expires_at  TIMESTAMPTZ NOT NULL,
    used_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_qr_tokens_token UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_qr_tokens_tenant ON qr_tokens (tenant_id);
CREATE INDEX IF NOT EXISTS idx_qr_tokens_expires ON qr_tokens (expires_at);
