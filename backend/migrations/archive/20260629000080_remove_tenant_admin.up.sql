-- Remove o tipo 'tenant_admin' do sistema.
-- O administrador do tenant passa a ser um 'funcionario' com cargo "Administrador"
-- e permissões completas atribuídas via permissoes_cargo.

SET search_path TO auth, public;

-- 1. Converter utilizadores existentes com tipo='tenant_admin' para 'funcionario'
UPDATE auth.users
   SET tipo = 'funcionario', updated_at = NOW()
 WHERE tipo = 'tenant_admin';

-- 2. Remover permissões-padrão associadas ao tipo 'tenant_admin'
DELETE FROM auth.permissoes_tipo WHERE tipo = 'tenant_admin';

-- 3. Actualizar o CHECK constraint — aceita apenas 'superadmin' e 'funcionario'
ALTER TABLE auth.users
    DROP CONSTRAINT IF EXISTS users_tipo_check;

ALTER TABLE auth.users
    ADD CONSTRAINT users_tipo_check CHECK (
        tipo = ANY (ARRAY['superadmin'::text, 'funcionario'::text])
    );
