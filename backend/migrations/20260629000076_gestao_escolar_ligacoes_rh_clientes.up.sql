-- ============================================================
-- Migration 076: Ligações opcionais Gestão Escolar → RH e Clientes
--
-- Adiciona campos de ligação entre entidades escolares e módulos
-- já existentes no ERP, sem criar dependências obrigatórias:
--
--   school_teachers.rh_employee_id → rh.funcionarios(id)
--     Permite ligar um professor ao seu registo no módulo RH
--     (para acesso a folha de pagamento, contratos, avaliações).
--
--   school_students.client_id → clientes.customers(id)
--     Permite ligar um aluno ao seu registo como cliente do ERP
--     (para integração com CRM, facturação, etc.).
--
--   school_guardians.client_id → clientes.customers(id)
--     Permite ligar um encarregado ao seu registo como cliente.
--
-- Todos os campos são NULLABLE e sem ON DELETE CASCADE —
-- a relação é opcional e o delete de um lado não afecta o outro.
-- ============================================================

SET search_path TO gestao_escolar, public;

-- ------------------------------------------------------------
-- 1. Professores → RH (opcional)
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'gestao_escolar'
          AND table_name   = 'school_teachers'
          AND column_name  = 'rh_employee_id'
    ) THEN
        ALTER TABLE gestao_escolar.school_teachers
            ADD COLUMN rh_employee_id BIGINT DEFAULT NULL;

        -- FK apenas se o módulo RH estiver instalado
        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'rh' AND table_name = 'funcionarios'
        ) THEN
            ALTER TABLE gestao_escolar.school_teachers
                ADD CONSTRAINT fk_teacher_rh_employee
                FOREIGN KEY (rh_employee_id)
                REFERENCES rh.funcionarios(id) ON DELETE SET NULL;
        END IF;

        CREATE INDEX IF NOT EXISTS idx_school_teachers_rh_employee
            ON gestao_escolar.school_teachers(tenant_id, rh_employee_id)
            WHERE rh_employee_id IS NOT NULL;
    END IF;
END $$;

-- ------------------------------------------------------------
-- 2. Alunos → Clientes (opcional)
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'gestao_escolar'
          AND table_name   = 'school_students'
          AND column_name  = 'client_id'
    ) THEN
        ALTER TABLE gestao_escolar.school_students
            ADD COLUMN client_id BIGINT DEFAULT NULL;

        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'clientes' AND table_name = 'customers'
        ) THEN
            ALTER TABLE gestao_escolar.school_students
                ADD CONSTRAINT fk_student_client
                FOREIGN KEY (client_id)
                REFERENCES clientes.customers(id) ON DELETE SET NULL;
        END IF;

        CREATE INDEX IF NOT EXISTS idx_school_students_client
            ON gestao_escolar.school_students(tenant_id, client_id)
            WHERE client_id IS NOT NULL;
    END IF;
END $$;

-- ------------------------------------------------------------
-- 3. Encarregados → Clientes (opcional)
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'gestao_escolar'
          AND table_name   = 'school_guardians'
          AND column_name  = 'client_id'
    ) THEN
        ALTER TABLE gestao_escolar.school_guardians
            ADD COLUMN client_id BIGINT DEFAULT NULL;

        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'clientes' AND table_name = 'customers'
        ) THEN
            ALTER TABLE gestao_escolar.school_guardians
                ADD CONSTRAINT fk_guardian_client
                FOREIGN KEY (client_id)
                REFERENCES clientes.customers(id) ON DELETE SET NULL;
        END IF;

        CREATE INDEX IF NOT EXISTS idx_school_guardians_client
            ON gestao_escolar.school_guardians(tenant_id, client_id)
            WHERE client_id IS NOT NULL;
    END IF;
END $$;
