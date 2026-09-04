-- Repoe a agenda pessoal do funcionario, lida por utilizadores.ListarAgenda e
-- escrita por CriarItemAgenda (internal/modules/utilizadores/handlers/agenda.go).
-- Foi criada em archive/20260722000001_utilizadores_agenda.up.sql mas nao
-- chegou ao baseline de 2026-07-24 -- todas as outras utilizadores.* dessa
-- altura sobreviveram, so esta ficou para tras. Sem ela o ecra de assiduidade
-- da app devolve 500 em GET /api/utilizadores/{id}/agenda a cada carregamento.
--
-- Sem tenant_id proprio, no mesmo padrao de utilizadores.user_notifications:
-- o tenant vem transitivamente do utilizador.
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

CREATE INDEX IF NOT EXISTS idx_user_agenda_user_data
    ON utilizadores.user_agenda (user_id, data);
