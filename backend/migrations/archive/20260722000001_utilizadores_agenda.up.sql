-- Agenda pessoal do funcionário (reuniões/eventos), no mesmo padrão de
-- utilizadores.user_notifications: dados pessoais ligados a auth.users,
-- sem tenant_id próprio (o tenant vem transitivamente do utilizador).

CREATE TABLE IF NOT EXISTS utilizadores.user_agenda (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    data DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fim TIME,
    tipo VARCHAR(30) NOT NULL DEFAULT 'reuniao'
        CHECK (tipo IN ('reuniao', 'workshop', 'outro')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_user_agenda_user_data ON utilizadores.user_agenda (user_id, data);
