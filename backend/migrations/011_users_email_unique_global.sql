SET search_path TO auth, public;

-- O login (auth.go) autentica apenas por email, sem contexto de tenant.
-- A constraint anterior (tenant_id, email) permitia o mesmo email em
-- tenants diferentes, fazendo o login escolher uma conta arbitrária
-- entre as duplicadas. Email passa a ser único globalmente: 1 conta = 1 tenant.
ALTER TABLE users DROP CONSTRAINT IF EXISTS uq_users_tenant_email;
ALTER TABLE users ADD CONSTRAINT uq_users_email UNIQUE (email);
