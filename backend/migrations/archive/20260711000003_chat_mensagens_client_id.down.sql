-- Reverte a adição de client_id.
DROP INDEX IF EXISTS idx_chat_mensagens_client_id;

ALTER TABLE chat_mensagens
    DROP COLUMN IF EXISTS client_id;
