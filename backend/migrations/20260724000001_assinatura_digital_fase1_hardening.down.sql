-- Reverte apenas o hardening introduzido pela migration correspondente.

DROP TRIGGER IF EXISTS trg_validacoes_append_only
    ON assinatura_digital.validacoes;
DROP TRIGGER IF EXISTS trg_versoes_assinadas_append_only
    ON assinatura_digital.versoes_assinadas;
DROP FUNCTION IF EXISTS assinatura_digital.evidencia_append_only();

ALTER TABLE assinatura_digital.validacoes
    DROP CONSTRAINT IF EXISTS fk_assdig_validacoes_versao_documento_tenant,
    DROP CONSTRAINT IF EXISTS fk_assdig_validacoes_documento_tenant;
ALTER TABLE assinatura_digital.validacoes
    ADD CONSTRAINT validacoes_documento_id_fkey
        FOREIGN KEY (documento_id)
        REFERENCES assinatura_digital.documentos(id)
        ON DELETE CASCADE,
    ADD CONSTRAINT validacoes_versao_id_fkey
        FOREIGN KEY (versao_id)
        REFERENCES assinatura_digital.versoes_assinadas(id);

ALTER TABLE assinatura_digital.convites
    DROP CONSTRAINT IF EXISTS fk_assdig_convites_signatario_documento_tenant,
    DROP CONSTRAINT IF EXISTS fk_assdig_convites_documento_tenant;
ALTER TABLE assinatura_digital.convites
    ADD CONSTRAINT convites_documento_id_fkey
        FOREIGN KEY (documento_id)
        REFERENCES assinatura_digital.documentos(id),
    ADD CONSTRAINT convites_signatario_id_fkey
        FOREIGN KEY (signatario_id)
        REFERENCES assinatura_digital.signatarios(id);

ALTER TABLE assinatura_digital.logs
    DROP CONSTRAINT IF EXISTS fk_assdig_logs_signatario_documento_tenant,
    DROP CONSTRAINT IF EXISTS fk_assdig_logs_documento_tenant;
ALTER TABLE assinatura_digital.logs
    ADD CONSTRAINT logs_documento_id_fkey
        FOREIGN KEY (documento_id)
        REFERENCES assinatura_digital.documentos(id),
    ADD CONSTRAINT logs_signatario_id_fkey
        FOREIGN KEY (signatario_id)
        REFERENCES assinatura_digital.signatarios(id);

ALTER TABLE assinatura_digital.versoes_assinadas
    DROP CONSTRAINT IF EXISTS fk_assdig_versoes_signatario_documento_tenant,
    DROP CONSTRAINT IF EXISTS fk_assdig_versoes_documento_tenant;
ALTER TABLE assinatura_digital.versoes_assinadas
    ADD CONSTRAINT versoes_assinadas_documento_id_fkey
        FOREIGN KEY (documento_id)
        REFERENCES assinatura_digital.documentos(id)
        ON DELETE CASCADE,
    ADD CONSTRAINT versoes_assinadas_signatario_id_fkey
        FOREIGN KEY (signatario_id)
        REFERENCES assinatura_digital.signatarios(id);

ALTER TABLE assinatura_digital.signatarios
    DROP CONSTRAINT IF EXISTS fk_assdig_signatarios_documento_tenant;
ALTER TABLE assinatura_digital.signatarios
    ADD CONSTRAINT signatarios_documento_id_fkey
        FOREIGN KEY (documento_id)
        REFERENCES assinatura_digital.documentos(id)
        ON DELETE CASCADE;

DROP INDEX IF EXISTS assinatura_digital.uq_assdig_versao_por_signatario;
DROP INDEX IF EXISTS assinatura_digital.uq_assdig_versoes_id_documento_tenant;
DROP INDEX IF EXISTS assinatura_digital.uq_assdig_signatarios_id_documento_tenant;
DROP INDEX IF EXISTS assinatura_digital.uq_assdig_documentos_id_tenant;

-- O estado não existe antes desta migration; ao reverter, documentos parciais
-- voltam a pendente para satisfazer a constraint anterior.
UPDATE assinatura_digital.documentos
SET status = 'pendente', updated_at = NOW()
WHERE status = 'parcialmente_assinado';

ALTER TABLE assinatura_digital.documentos
    DROP CONSTRAINT IF EXISTS documentos_status_check;
ALTER TABLE assinatura_digital.documentos
    ADD CONSTRAINT documentos_status_check
    CHECK (status IN ('rascunho', 'pendente', 'assinado', 'cancelado', 'expirado'));
