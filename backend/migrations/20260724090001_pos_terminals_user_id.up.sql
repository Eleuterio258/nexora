-- Adiciona pos.pos_terminals.user_id — a conta sintética que autentica o
-- terminal no auto-login (POST /api/pos/login, tipo=terminal).
--
-- O código Go (auth.loginTerminalPOS faz JOIN auth.users u ON u.id = t.user_id;
-- pos.CriarTerminal insere com user_id) já assumia esta coluna, mas ela não
-- existia no esquema baseline — pelo que criar/auto-login de terminais estava
-- inoperacional. Esta migração alinha o schema com o código.

ALTER TABLE pos.pos_terminals
    ADD COLUMN IF NOT EXISTS user_id BIGINT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pos_terminals_user_id_fkey'
    ) THEN
        ALTER TABLE pos.pos_terminals
            ADD CONSTRAINT pos_terminals_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_pos_terminals_user_id
    ON pos.pos_terminals (user_id);
