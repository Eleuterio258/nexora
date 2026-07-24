-- Fase 3 (arranque) do módulo assinatura-digital: índices para o portal de
-- verificação pública por hash, e rastreabilidade da origem do documento
-- quando criado a partir de outro módulo (ex.: recursos-humanos).

CREATE INDEX IF NOT EXISTS idx_documentos_hash ON assinatura_digital.documentos(hash_sha256);
CREATE INDEX IF NOT EXISTS idx_versoes_hash ON assinatura_digital.versoes_assinadas(hash_sha256);

ALTER TABLE assinatura_digital.documentos
    ADD COLUMN IF NOT EXISTS origem_modulo VARCHAR(50),
    ADD COLUMN IF NOT EXISTS origem_id BIGINT;
