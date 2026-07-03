-- ============================================================
-- Migration 067: Integração Financeira do Módulo Escolar
-- ============================================================

SET search_path TO gestao_escolar, public;

-- ------------------------------------------------------------
-- 1. Configuração financeira escolar
-- ------------------------------------------------------------
-- Nota: os movimentos de tesouraria são registados em tesouraria.movements
-- (schema padronizado em inglês). A tabela legado movimentos_financeiros foi removida.

-- ------------------------------------------------------------
-- 2. Garantir configuração financeira escolar
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_financial_config (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL UNIQUE,
    conta_receita_id BIGINT,
    conta_bancaria_id BIGINT,
    centro_custo_id BIGINT,
    criar_movimento_financeiro BOOLEAN NOT NULL DEFAULT FALSE,
    criar_movimento_tesouraria BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 3. Índice útil para conciliação
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_school_payments_external
    ON gestao_escolar.school_payments(tenant_id, external_id)
    WHERE external_id IS NOT NULL;
