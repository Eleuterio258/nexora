ALTER TABLE assinatura_digital.versoes_assinadas
    DROP COLUMN IF EXISTS localizacao,
    DROP COLUMN IF EXISTS motivo,
    DROP COLUMN IF EXISTS timestamp_autoridade,
    DROP COLUMN IF EXISTS algoritmo_assinatura,
    DROP COLUMN IF EXISTS algoritmo_digest,
    DROP COLUMN IF EXISTS certificado_validade_fim,
    DROP COLUMN IF EXISTS certificado_validade_inicio,
    DROP COLUMN IF EXISTS certificado_fingerprint,
    DROP COLUMN IF EXISTS certificado_serie,
    DROP COLUMN IF EXISTS certificado_emissor,
    DROP COLUMN IF EXISTS certificado_subject,
    DROP COLUMN IF EXISTS legal_valido,
    DROP COLUMN IF EXISTS provider;
