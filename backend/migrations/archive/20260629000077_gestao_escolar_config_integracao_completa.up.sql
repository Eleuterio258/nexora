-- ============================================================
-- Migration 077: Configuração completa de integração do módulo escolar
--
-- Adiciona flags e campos para as novas integrações:
--   - Contabilidade: criar lançamentos automáticos
--   - Faturação: emitir recibos automáticos (tipo RB)
--   - Centro de custo: conta para alocação de receitas
--   - Conta de débito: conta bancária/caixa para journal entry
-- ============================================================

SET search_path TO gestao_escolar, public;

-- Adicionar colunas de integração se não existirem
DO $$
BEGIN
    -- Integração com Contabilidade
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'gestao_escolar'
          AND table_name   = 'school_financial_config'
          AND column_name  = 'criar_lancamento_contabilidade'
    ) THEN
        ALTER TABLE gestao_escolar.school_financial_config
            ADD COLUMN criar_lancamento_contabilidade BOOLEAN NOT NULL DEFAULT FALSE,
            ADD COLUMN conta_debito_id  BIGINT DEFAULT NULL, -- conta de ativo (bancária/caixa)
            ADD COLUMN conta_credito_id BIGINT DEFAULT NULL; -- conta de receita de propinas
    END IF;

    -- Integração com Faturação
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'gestao_escolar'
          AND table_name   = 'school_financial_config'
          AND column_name  = 'criar_recibo_faturacao'
    ) THEN
        ALTER TABLE gestao_escolar.school_financial_config
            ADD COLUMN criar_recibo_faturacao BOOLEAN NOT NULL DEFAULT FALSE,
            ADD COLUMN customer_group_id BIGINT DEFAULT NULL; -- grupo de clientes para encarregados
    END IF;
END $$;

-- ------------------------------------------------------------
-- Configurações escolares padrão em sistema_configuracao.settings
-- (registadas para cada tenant existente que já use escola)
-- ------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'sistema_configuracao' AND table_name = 'settings'
    ) THEN
        INSERT INTO sistema_configuracao.settings (tenant_id, chave, valor, escopo)
        SELECT t.tenant_id, k.chave, k.valor, 'tenant'
        FROM gestao_escolar.school_financial_config t
        CROSS JOIN (VALUES
            ('school.usa_tesouraria',        'false'),
            ('school.usa_financeiro',        'false'),
            ('school.usa_contabilidade',     'false'),
            ('school.usa_faturacao_recibos', 'false'),
            ('school.moeda_padrao',          'MZN'),
            ('school.dias_vencimento',       '30')
        ) AS k(chave, valor)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
