-- Adiciona foreign keys de tenant e relacionamentos internos ao schema auth.
-- Garante integridade referencial entre users, cargos, api_keys, sessions e saas.tenants.
-- Cada ALTER TABLE é executado num bloco isolado para ser idempotente caso a
-- constraint já exista.

SET search_path TO auth, saas, public;

DO $$
BEGIN
    -- auth.users -> saas.tenants + auth.cargos
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_users_tenant' AND conrelid = 'auth.users'::regclass
    ) THEN
        ALTER TABLE auth.users ADD CONSTRAINT fk_users_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_users_cargo' AND conrelid = 'auth.users'::regclass
    ) THEN
        ALTER TABLE auth.users ADD CONSTRAINT fk_users_cargo FOREIGN KEY (cargo_id) REFERENCES auth.cargos(id) ON DELETE SET NULL;
    END IF;

    -- auth.cargos -> saas.tenants
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_cargos_tenant' AND conrelid = 'auth.cargos'::regclass
    ) THEN
        ALTER TABLE auth.cargos ADD CONSTRAINT fk_cargos_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
    END IF;

    -- auth.api_keys -> saas.tenants + auth.users
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_api_keys_tenant' AND conrelid = 'auth.api_keys'::regclass
    ) THEN
        ALTER TABLE auth.api_keys ADD CONSTRAINT fk_api_keys_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_api_keys_user' AND conrelid = 'auth.api_keys'::regclass
    ) THEN
        ALTER TABLE auth.api_keys ADD CONSTRAINT fk_api_keys_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    -- auth.sessions -> auth.users
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_sessions_user' AND conrelid = 'auth.sessions'::regclass
    ) THEN
        ALTER TABLE auth.sessions ADD CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;
