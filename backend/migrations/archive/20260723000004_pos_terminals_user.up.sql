-- Liga cada terminal POS a uma conta comum de utilizador (auth.users), que o
-- autentica via login unico (POST /api/pos/login, tipo=terminal). O terminal
-- passa a ser tratado como um funcionario com um cargo dedicado ("Terminal
-- POS", permissao pos:operar_pos), reaproveitando o RBAC existente em vez de
-- um esquema de autenticacao proprio.
ALTER TABLE pos.pos_terminals
    ADD COLUMN user_id BIGINT REFERENCES auth.users(id) ON DELETE SET NULL;
