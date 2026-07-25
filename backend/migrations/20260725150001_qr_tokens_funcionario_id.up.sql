-- Adiciona vínculo opcional entre token QR e funcionário.
-- Necessário para o modo "QR Code do Funcionário", em que o gestor lê o QR
-- pessoal do colaborador e o sistema identifica o funcionário automaticamente.

SET search_path TO rh, public;

ALTER TABLE rh.qr_tokens
    ADD COLUMN IF NOT EXISTS funcionario_id bigint;

CREATE INDEX IF NOT EXISTS idx_qr_tokens_funcionario
    ON rh.qr_tokens (tenant_id, funcionario_id);
