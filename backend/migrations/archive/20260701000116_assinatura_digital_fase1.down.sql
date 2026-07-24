DELETE FROM auth.permissoes_cargo
WHERE modulo = 'assinatura-digital' AND acao = 'assinar_documentos';

DROP TRIGGER IF EXISTS trg_logs_imutavel ON assinatura_digital.logs;
DROP FUNCTION IF EXISTS assinatura_digital.logs_imutavel();

ALTER TABLE assinatura_digital.logs DROP CONSTRAINT IF EXISTS logs_documento_id_fkey;
ALTER TABLE assinatura_digital.logs
    ADD CONSTRAINT logs_documento_id_fkey FOREIGN KEY (documento_id)
    REFERENCES assinatura_digital.documentos(id) ON DELETE CASCADE;

DROP TABLE IF EXISTS assinatura_digital.convites;

ALTER TABLE assinatura_digital.signatarios
    DROP COLUMN IF EXISTS recusado_em,
    DROP COLUMN IF EXISTS motivo_recusa,
    DROP COLUMN IF EXISTS user_id;
