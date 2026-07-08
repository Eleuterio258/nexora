-- ============================================================
-- Migration: Suporte a contratação integrada Recrutamento → RH
-- ============================================================
-- 1. Permite estado 'contratado' nas candidaturas.
-- 2. Guarda referência do funcionário RH criado.
-- 3. Adiciona campos legais mínimos ao funcionário (Moçambique).
-- 4. Adiciona consentimento de dados à candidatura.
-- ============================================================

SET search_path TO recrutamento, public;

-- 1. Estado 'contratado'
ALTER TABLE candidaturas
  DROP CONSTRAINT IF EXISTS candidaturas_estado_check;

ALTER TABLE candidaturas
  ADD CONSTRAINT candidaturas_estado_check
  CHECK (estado IN ('recebida','em_analise','entrevista','aprovada','rejeitada','contratado'));

-- 2. Referência ao funcionário RH criado
ALTER TABLE candidaturas
  ADD COLUMN IF NOT EXISTS rh_funcionario_id BIGINT;

ALTER TABLE candidaturas
  ADD CONSTRAINT fk_candidaturas_rh_funcionario
  FOREIGN KEY (rh_funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_candidaturas_rh_funcionario_id
  ON candidaturas (rh_funcionario_id);

-- 3. Consentimento de dados pessoais (Lei do Trabalho de Moçambique)
ALTER TABLE candidaturas
  ADD COLUMN IF NOT EXISTS consentimento_dados BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS data_consentimento TIMESTAMPTZ;

SET search_path TO rh, public;

-- 4. Campos legais mínimos do funcionário
ALTER TABLE funcionarios
  ADD COLUMN IF NOT EXISTS nacionalidade VARCHAR(60),
  ADD COLUMN IF NOT EXISTS tipo_documento VARCHAR(30),
  ADD COLUMN IF NOT EXISTS numero_documento VARCHAR(60);

-- 5. Notificação automática de contratação
SET search_path TO recrutamento, public;
ALTER TABLE config_notificacoes
  ADD COLUMN IF NOT EXISTS notificar_contratado BOOLEAN NOT NULL DEFAULT TRUE;
