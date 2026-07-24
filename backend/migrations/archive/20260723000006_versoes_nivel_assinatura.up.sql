-- Adiciona nível da assinatura às versões assinadas.
ALTER TABLE assinatura_digital.versoes_assinadas
    ADD COLUMN IF NOT EXISTS nivel_assinatura VARCHAR(20) NOT NULL DEFAULT 'simples';
