SET search_path TO notifications, public;

-- Tokens de dispositivo para notificações push (FCM), agnóstico ao módulo:
-- qualquer principal autenticado (candidato, aluno, encarregado, funcionário)
-- acaba sempre ligado a uma linha em auth.users — por isso este registo é
-- feito por user_id, e não por tabela/tipo específico de cada portal.
CREATE TABLE IF NOT EXISTS push_tokens (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token VARCHAR(255) NOT NULL,
    platform VARCHAR(20) NOT NULL DEFAULT 'android',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_push_tokens_token UNIQUE (token),
    CONSTRAINT fk_push_tokens_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_tokens (user_id);
