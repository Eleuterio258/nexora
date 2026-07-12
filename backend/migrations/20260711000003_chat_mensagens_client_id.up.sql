-- Adiciona client_id às mensagens de chat para ACK fiável e deduplicação.
ALTER TABLE chat_mensagens
    ADD COLUMN IF NOT EXISTS client_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_mensagens_client_id
    ON chat_mensagens(conversa_id, client_id)
    WHERE client_id IS NOT NULL AND client_id <> '';
