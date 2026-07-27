-- Reverte as alterações de uniformização de identificadores de funcionário.

SET search_path TO rh, public;

ALTER TABLE rh.funcionarios
    DROP CONSTRAINT IF EXISTS uq_funcionarios_tenant_email;

DROP INDEX IF EXISTS uq_funcionarios_tenant_numero;
DROP INDEX IF EXISTS idx_funcionarios_tenant_email;
DROP INDEX IF EXISTS idx_funcionarios_email;
DROP INDEX IF EXISTS idx_funcionarios_user_id;

-- Não removemos as colunas user_id e email para não perder dados;
-- apenas removemos as constraints/índices adicionadas por esta migration.
