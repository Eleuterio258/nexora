-- Tabela de validações de documentos assinados.
-- Guarda o resultado de cada validação (automática ou solicitada) para
-- rastreabilidade e auditoria.
CREATE TABLE IF NOT EXISTS assinatura_digital.validacoes (
    id              BIGSERIAL PRIMARY KEY,
    documento_id    BIGINT NOT NULL REFERENCES assinatura_digital.documentos(id) ON DELETE CASCADE,
    tenant_id       BIGINT NOT NULL,
    versao_id       BIGINT REFERENCES assinatura_digital.versoes_assinadas(id),
    hash_verificado VARCHAR(64),
    assinaturas     INT DEFAULT 0,
    certificado_valido BOOLEAN,
    certificado_motivo TEXT,
    resultado       VARCHAR(20) NOT NULL, -- valido, invalido, parcial
    detalhes        JSONB,
    user_id         BIGINT,
    ip_address      INET,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_validacoes_documento ON assinatura_digital.validacoes(documento_id);
