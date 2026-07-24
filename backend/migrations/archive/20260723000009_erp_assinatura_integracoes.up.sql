-- Adiciona suporte a assinatura digital nos restantes módulos ERP.

-- Aprovações: decisões de aprovação (signatário interno do nível actual)
ALTER TABLE saas.approval_requests
    ADD COLUMN IF NOT EXISTS ficheiro_url VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;

-- Recrutamento: proposta/aceitação do candidato (signatário externo)
ALTER TABLE recrutamento.candidaturas
    ADD COLUMN IF NOT EXISTS ficheiro_url VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;

-- Contabilidade: relatórios contabilísticos (signatário interno)
ALTER TABLE contabilidade.accounting_reports
    ADD COLUMN IF NOT EXISTS ficheiro_url VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;

-- Tesouraria: reconciliações bancárias (signatário interno)
ALTER TABLE tesouraria.reconciliations
    ADD COLUMN IF NOT EXISTS ficheiro_url VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;

-- Gestão Escolar: matrículas (signatário externo — encarregado)
ALTER TABLE gestao_escolar.school_enrollments
    ADD COLUMN IF NOT EXISTS ficheiro_url VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;

-- Empresas: documentos da empresa (signatário externo — contacto principal)
ALTER TABLE empresas.company_documents
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;

-- Auditoria: documentos de auditoria assináveis (signatário interno)
CREATE TABLE IF NOT EXISTS auditoria.audit_documents (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    ficheiro_url VARCHAR(1000),
    pdf_storage_key VARCHAR(500),
    assinatura_documento_id BIGINT,
    user_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Segurança: políticas de segurança (signatário interno)
ALTER TABLE seguranca.security_policies
    ADD COLUMN IF NOT EXISTS ficheiro_url VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS pdf_storage_key VARCHAR(500),
    ADD COLUMN IF NOT EXISTS assinatura_documento_id BIGINT;
