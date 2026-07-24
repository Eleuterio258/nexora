-- Assinatura digital — Fase 1 de hardening:
--   * estados coerentes com os handlers;
--   * isolamento de tenant garantido por FKs compostas;
--   * evidências append-only;
--   * remoção de cascatas destrutivas;
--   * uma única versão criptográfica por signatário.

-- O webhook usa este estado quando ainda existem signatários pendentes.
ALTER TABLE assinatura_digital.documentos
    DROP CONSTRAINT IF EXISTS documentos_status_check;
ALTER TABLE assinatura_digital.documentos
    ADD CONSTRAINT documentos_status_check
    CHECK (status IN (
        'rascunho',
        'pendente',
        'parcialmente_assinado',
        'assinado',
        'cancelado',
        'expirado'
    ));

-- Falhar explicitamente antes de criar as FKs caso dados legados atravessem
-- tenants ou relacionem uma versão/convite/validação com o documento errado.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM assinatura_digital.signatarios s
        JOIN assinatura_digital.documentos d ON d.id = s.documento_id
        WHERE s.tenant_id <> d.tenant_id
    ) THEN
        RAISE EXCEPTION 'assinatura-digital: signatários com tenant diferente do documento';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM assinatura_digital.versoes_assinadas v
        JOIN assinatura_digital.documentos d ON d.id = v.documento_id
        WHERE v.tenant_id <> d.tenant_id
    ) THEN
        RAISE EXCEPTION 'assinatura-digital: versões com tenant diferente do documento';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM assinatura_digital.versoes_assinadas v
        JOIN assinatura_digital.signatarios s ON s.id = v.signatario_id
        WHERE s.documento_id <> v.documento_id OR s.tenant_id <> v.tenant_id
    ) THEN
        RAISE EXCEPTION 'assinatura-digital: versões relacionadas com signatário de outro documento/tenant';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM assinatura_digital.convites c
        JOIN assinatura_digital.documentos d ON d.id = c.documento_id
        JOIN assinatura_digital.signatarios s ON s.id = c.signatario_id
        WHERE c.tenant_id <> d.tenant_id
           OR s.documento_id <> c.documento_id
           OR s.tenant_id <> c.tenant_id
    ) THEN
        RAISE EXCEPTION 'assinatura-digital: convites relacionados com documento/signatário de outro tenant';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM assinatura_digital.logs l
        JOIN assinatura_digital.documentos d ON d.id = l.documento_id
        LEFT JOIN assinatura_digital.signatarios s ON s.id = l.signatario_id
        WHERE l.tenant_id <> d.tenant_id
           OR (
               l.signatario_id IS NOT NULL
               AND (
                   s.id IS NULL
                   OR s.documento_id <> l.documento_id
                   OR s.tenant_id <> l.tenant_id
               )
           )
    ) THEN
        RAISE EXCEPTION 'assinatura-digital: logs relacionados com documento/signatário de outro tenant';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM assinatura_digital.validacoes va
        JOIN assinatura_digital.documentos d ON d.id = va.documento_id
        LEFT JOIN assinatura_digital.versoes_assinadas v ON v.id = va.versao_id
        WHERE va.tenant_id <> d.tenant_id
           OR (
               va.versao_id IS NOT NULL
               AND (
                   v.id IS NULL
                   OR v.documento_id <> va.documento_id
                   OR v.tenant_id <> va.tenant_id
               )
           )
    ) THEN
        RAISE EXCEPTION 'assinatura-digital: validações relacionadas com documento/versão de outro tenant';
    END IF;

    IF EXISTS (
        SELECT documento_id, signatario_id
        FROM assinatura_digital.versoes_assinadas
        WHERE signatario_id IS NOT NULL
        GROUP BY documento_id, signatario_id
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'assinatura-digital: existem versões duplicadas para o mesmo signatário';
    END IF;
END;
$$;

-- Chaves candidatas necessárias para as FKs compostas. O id continua a ser a
-- PK; estas chaves permitem que o PostgreSQL também imponha tenant/documento.
CREATE UNIQUE INDEX IF NOT EXISTS uq_assdig_documentos_id_tenant
    ON assinatura_digital.documentos(id, tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_assdig_signatarios_id_documento_tenant
    ON assinatura_digital.signatarios(id, documento_id, tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_assdig_versoes_id_documento_tenant
    ON assinatura_digital.versoes_assinadas(id, documento_id, tenant_id);

-- Um signatário só pode originar uma versão criptográfica. O índice é parcial
-- para continuar a permitir versões técnicas sem signatário associado.
CREATE UNIQUE INDEX IF NOT EXISTS uq_assdig_versao_por_signatario
    ON assinatura_digital.versoes_assinadas(documento_id, signatario_id)
    WHERE signatario_id IS NOT NULL;

-- Substituir FKs simples/cascade por relações compostas e não destrutivas.
ALTER TABLE assinatura_digital.signatarios
    DROP CONSTRAINT IF EXISTS signatarios_documento_id_fkey;
ALTER TABLE assinatura_digital.signatarios
    ADD CONSTRAINT fk_assdig_signatarios_documento_tenant
    FOREIGN KEY (documento_id, tenant_id)
    REFERENCES assinatura_digital.documentos(id, tenant_id)
    ON DELETE RESTRICT;

ALTER TABLE assinatura_digital.versoes_assinadas
    DROP CONSTRAINT IF EXISTS versoes_assinadas_documento_id_fkey,
    DROP CONSTRAINT IF EXISTS versoes_assinadas_signatario_id_fkey;
ALTER TABLE assinatura_digital.versoes_assinadas
    ADD CONSTRAINT fk_assdig_versoes_documento_tenant
        FOREIGN KEY (documento_id, tenant_id)
        REFERENCES assinatura_digital.documentos(id, tenant_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_assdig_versoes_signatario_documento_tenant
        FOREIGN KEY (signatario_id, documento_id, tenant_id)
        REFERENCES assinatura_digital.signatarios(id, documento_id, tenant_id)
        ON DELETE RESTRICT;

ALTER TABLE assinatura_digital.logs
    DROP CONSTRAINT IF EXISTS logs_documento_id_fkey,
    DROP CONSTRAINT IF EXISTS logs_signatario_id_fkey;
ALTER TABLE assinatura_digital.logs
    ADD CONSTRAINT fk_assdig_logs_documento_tenant
        FOREIGN KEY (documento_id, tenant_id)
        REFERENCES assinatura_digital.documentos(id, tenant_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_assdig_logs_signatario_documento_tenant
        FOREIGN KEY (signatario_id, documento_id, tenant_id)
        REFERENCES assinatura_digital.signatarios(id, documento_id, tenant_id)
        ON DELETE RESTRICT;

ALTER TABLE assinatura_digital.convites
    DROP CONSTRAINT IF EXISTS convites_documento_id_fkey,
    DROP CONSTRAINT IF EXISTS convites_signatario_id_fkey;
ALTER TABLE assinatura_digital.convites
    ADD CONSTRAINT fk_assdig_convites_documento_tenant
        FOREIGN KEY (documento_id, tenant_id)
        REFERENCES assinatura_digital.documentos(id, tenant_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_assdig_convites_signatario_documento_tenant
        FOREIGN KEY (signatario_id, documento_id, tenant_id)
        REFERENCES assinatura_digital.signatarios(id, documento_id, tenant_id)
        ON DELETE RESTRICT;

ALTER TABLE assinatura_digital.validacoes
    DROP CONSTRAINT IF EXISTS validacoes_documento_id_fkey,
    DROP CONSTRAINT IF EXISTS validacoes_versao_id_fkey;
ALTER TABLE assinatura_digital.validacoes
    ADD CONSTRAINT fk_assdig_validacoes_documento_tenant
        FOREIGN KEY (documento_id, tenant_id)
        REFERENCES assinatura_digital.documentos(id, tenant_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_assdig_validacoes_versao_documento_tenant
        FOREIGN KEY (versao_id, documento_id, tenant_id)
        REFERENCES assinatura_digital.versoes_assinadas(id, documento_id, tenant_id)
        ON DELETE RESTRICT;

-- Evidências são append-only. INSERT continua permitido; alterações e remoções
-- exigem um processo administrativo fora da aplicação e uma migration explícita.
CREATE OR REPLACE FUNCTION assinatura_digital.evidencia_append_only()
RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'A evidência %.% é append-only e não pode ser alterada nem eliminada',
        TG_TABLE_SCHEMA, TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_versoes_assinadas_append_only
    ON assinatura_digital.versoes_assinadas;
CREATE TRIGGER trg_versoes_assinadas_append_only
    BEFORE UPDATE OR DELETE ON assinatura_digital.versoes_assinadas
    FOR EACH ROW EXECUTE FUNCTION assinatura_digital.evidencia_append_only();

DROP TRIGGER IF EXISTS trg_validacoes_append_only
    ON assinatura_digital.validacoes;
CREATE TRIGGER trg_validacoes_append_only
    BEFORE UPDATE OR DELETE ON assinatura_digital.validacoes
    FOR EACH ROW EXECUTE FUNCTION assinatura_digital.evidencia_append_only();
