-- Ligação Facturação → Contabilidade: configuração por tenant de qual diário
-- e quais contas usar ao gerar o lançamento contabilístico automático na
-- emissão de facturas (EmitirFaturaFiscal). Sem registo activo, a emissão de
-- facturas continua a funcionar normalmente, apenas sem lançamento contábil.
CREATE TABLE IF NOT EXISTS faturacao.config_contabilidade (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id bigint NOT NULL,
    accounting_journal_id bigint NOT NULL,
    conta_clientes_id bigint NOT NULL,
    conta_receita_id bigint NOT NULL,
    conta_iva_id bigint,
    ativo boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_faturacao_config_contabilidade_tenant UNIQUE (tenant_id)
);

-- Rastreio do lançamento contabilístico gerado para cada factura/nota de
-- crédito, para idempotência (não gerar duas vezes) e para anular o
-- lançamento se o documento for cancelado.
ALTER TABLE faturacao.invoices
    ADD COLUMN IF NOT EXISTS journal_entry_id bigint;
ALTER TABLE faturacao.credit_notes
    ADD COLUMN IF NOT EXISTS journal_entry_id bigint;

-- Diário/contas para a integração propinas → Contabilidade da Gestão Escolar,
-- que usa o mesmo AccountingAdapter genérico (antes desta migração o adapter
-- gravava em colunas inexistentes e a integração falhava sempre — ver
-- internal/shared/adapters/accounting.go).
ALTER TABLE gestao_escolar.school_financial_config
    ADD COLUMN IF NOT EXISTS accounting_journal_id bigint;
