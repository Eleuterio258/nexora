-- Reverte adições de assinatura digital nos restantes módulos ERP.

ALTER TABLE saas.approval_requests
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;

ALTER TABLE recrutamento.candidaturas
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;

ALTER TABLE contabilidade.accounting_reports
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;

ALTER TABLE tesouraria.reconciliations
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;

ALTER TABLE gestao_escolar.school_enrollments
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;

ALTER TABLE empresas.company_documents
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;

DROP TABLE IF EXISTS auditoria.audit_documents;

ALTER TABLE seguranca.security_policies
    DROP COLUMN IF EXISTS ficheiro_url,
    DROP COLUMN IF EXISTS pdf_storage_key,
    DROP COLUMN IF EXISTS assinatura_documento_id;
