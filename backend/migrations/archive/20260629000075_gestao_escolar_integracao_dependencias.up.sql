-- ============================================================
-- Migration 075: Integração de dependências do Módulo Escolar
--
-- Resolve:
--   1. FK: school_financial_config.conta_bancaria_id → tesouraria.bank_accounts
--   2. FK: school_financial_config.centro_custo_id → centros_custo.cost_centers
--
-- Nota: a tabela legado tesouraria.movimentos_financeiros foi removida.
-- Os movimentos são registados em tesouraria.movements.
-- ============================================================

SET search_path TO gestao_escolar, public;

-- ------------------------------------------------------------
-- 1. FK: conta_bancaria_id → tesouraria.bank_accounts
--    Adicionado apenas se a tabela bank_accounts existe
-- ------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'tesouraria' AND table_name = 'bank_accounts'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema    = 'gestao_escolar'
          AND table_name      = 'school_financial_config'
          AND constraint_name = 'fk_school_fin_config_bank_account'
    ) THEN
        ALTER TABLE gestao_escolar.school_financial_config
            ADD CONSTRAINT fk_school_fin_config_bank_account
            FOREIGN KEY (conta_bancaria_id)
            REFERENCES tesouraria.bank_accounts(id) ON DELETE SET NULL;
    END IF;
END $$;

-- ------------------------------------------------------------
-- 4. FK: centro_custo_id → centros_custo.cost_centers
-- ------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'centros_custo' AND table_name = 'cost_centers'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema    = 'gestao_escolar'
          AND table_name      = 'school_financial_config'
          AND constraint_name = 'fk_school_fin_config_centro_custo'
    ) THEN
        ALTER TABLE gestao_escolar.school_financial_config
            ADD CONSTRAINT fk_school_fin_config_centro_custo
            FOREIGN KEY (centro_custo_id)
            REFERENCES centros_custo.cost_centers(id) ON DELETE SET NULL;
    END IF;
END $$;
