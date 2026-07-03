-- Adiciona integridade referencial entre o schema RBAC legado (autorizacao)
-- e o novo schema de autenticação (auth).

SET search_path TO autorizacao, auth, public;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_roles_user'
          AND conrelid = 'autorizacao.user_roles'::regclass
    ) THEN
        ALTER TABLE autorizacao.user_roles
            ADD CONSTRAINT fk_user_roles_user
            FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;
