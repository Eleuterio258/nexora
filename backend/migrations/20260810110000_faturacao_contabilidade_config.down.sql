ALTER TABLE gestao_escolar.school_financial_config
    DROP COLUMN IF EXISTS accounting_journal_id;

ALTER TABLE faturacao.invoices
    DROP COLUMN IF EXISTS journal_entry_id;
ALTER TABLE faturacao.credit_notes
    DROP COLUMN IF EXISTS journal_entry_id;

DROP TABLE IF EXISTS faturacao.config_contabilidade;
