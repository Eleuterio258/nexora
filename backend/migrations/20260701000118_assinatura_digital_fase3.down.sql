ALTER TABLE assinatura_digital.documentos
    DROP COLUMN IF EXISTS origem_id,
    DROP COLUMN IF EXISTS origem_modulo;

DROP INDEX IF EXISTS assinatura_digital.idx_versoes_hash;
DROP INDEX IF EXISTS assinatura_digital.idx_documentos_hash;
