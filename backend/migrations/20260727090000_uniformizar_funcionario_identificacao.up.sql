-- Uniformiza os identificadores de funcionário para suportar resolução centralizada.
-- Garante que rh.funcionarios tem as colunas e índices necessários para resolver
-- um funcionário por funcionario_id, employee_no (numero_funcionario), user_id ou email.

SET search_path TO rh, public;

-- Colunas necessárias (já deveriam existir, mas garantimos idempotência)
ALTER TABLE rh.funcionarios
    ADD COLUMN IF NOT EXISTS user_id BIGINT,
    ADD COLUMN IF NOT EXISTS email VARCHAR(150);

-- Índices para lookup eficiente e consistente
CREATE INDEX IF NOT EXISTS idx_funcionarios_user_id ON rh.funcionarios (user_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_email ON rh.funcionarios (email) WHERE email IS NOT NULL AND email <> '';
CREATE INDEX IF NOT EXISTS idx_funcionarios_tenant_email ON rh.funcionarios (tenant_id, email) WHERE email IS NOT NULL AND email <> '';

-- Garantir unicidade de email por tenant (quando preenchido)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_funcionarios_tenant_email'
          AND conrelid = 'rh.funcionarios'::regclass
    ) THEN
        ALTER TABLE rh.funcionarios
            ADD CONSTRAINT uq_funcionarios_tenant_email
            UNIQUE (tenant_id, email)
            WHERE email IS NOT NULL AND email <> '';
    END IF;
END $$;

-- Garantir unicidade de numero_funcionario por tenant (quando preenchido)
-- O baseline já deve ter criado este índice; repetimos IF NOT EXISTS por segurança.
CREATE UNIQUE INDEX IF NOT EXISTS uq_funcionarios_tenant_numero
    ON rh.funcionarios (tenant_id, numero_funcionario)
    WHERE numero_funcionario IS NOT NULL AND numero_funcionario <> '';
