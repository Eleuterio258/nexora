SET search_path TO rh, public;

DROP INDEX IF EXISTS rh.idx_qr_tokens_funcionario;

ALTER TABLE rh.qr_tokens
    DROP COLUMN IF EXISTS funcionario_id;
