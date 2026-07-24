-- Fase 2 (arranque) do módulo assinatura-digital: evidências de assinatura
-- PAdES em assinatura_digital.versoes_assinadas (tabela já existia, mas
-- nunca tinha sido usada). Suporta o provider de desenvolvimento (dev) e
-- qualquer provider real que venha a substituí-lo.

ALTER TABLE assinatura_digital.versoes_assinadas
    ADD COLUMN IF NOT EXISTS provider VARCHAR(50),
    ADD COLUMN IF NOT EXISTS legal_valido BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS certificado_subject TEXT,
    ADD COLUMN IF NOT EXISTS certificado_emissor TEXT,
    ADD COLUMN IF NOT EXISTS certificado_serie VARCHAR(100),
    ADD COLUMN IF NOT EXISTS certificado_fingerprint VARCHAR(100),
    ADD COLUMN IF NOT EXISTS certificado_validade_inicio TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS certificado_validade_fim TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS algoritmo_digest VARCHAR(30),
    ADD COLUMN IF NOT EXISTS algoritmo_assinatura VARCHAR(30),
    ADD COLUMN IF NOT EXISTS timestamp_autoridade VARCHAR(255),
    ADD COLUMN IF NOT EXISTS motivo TEXT,
    ADD COLUMN IF NOT EXISTS localizacao TEXT;
