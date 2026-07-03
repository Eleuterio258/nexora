-- ═══════════════════════════════════════════════════════════════
--  RH - Configuração Contabilística da Folha Salarial (Fase 2)
-- ═══════════════════════════════════════════════════════════════
SET search_path TO rh, public;

-- Configuração de mapeamento de contas para lançamento de folha salarial
CREATE TABLE IF NOT EXISTS config_contabilidade_folha (
    id                      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id               BIGINT NOT NULL,
    accounting_journal_id   BIGINT NOT NULL REFERENCES contabilidade.accounting_journals(id),
    conta_despesa_salarios  BIGINT NOT NULL REFERENCES contabilidade.chart_of_accounts(id),
    conta_inss_trabalhador  BIGINT NOT NULL REFERENCES contabilidade.chart_of_accounts(id),
    conta_irps              BIGINT NOT NULL REFERENCES contabilidade.chart_of_accounts(id),
    conta_salarios_a_pagar  BIGINT NOT NULL REFERENCES contabilidade.chart_of_accounts(id),
    conta_adiantamentos     BIGINT REFERENCES contabilidade.chart_of_accounts(id),
    conta_inss_patronal     BIGINT REFERENCES contabilidade.chart_of_accounts(id),
    taxa_inss_patronal      NUMERIC(5,4) NOT NULL DEFAULT 0.07,
    ativo                   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_config_contabilidade_folha_tenant UNIQUE (tenant_id)
);

-- Referência do lançamento contabilístico na folha
ALTER TABLE folhas_pagamento
    ADD COLUMN IF NOT EXISTS journal_entry_id BIGINT REFERENCES contabilidade.journal_entries(id);

CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_journal_entry
    ON folhas_pagamento (tenant_id, journal_entry_id);
