-- Reverte a Fase 4: recria as colunas removidas (vazias - os dados antigos
-- nao sao recuperaveis, ja que na pratica estavam congelados nos valores
-- por omissao havia muito tempo).

ALTER TABLE gestao_escolar.school_students
  ADD COLUMN IF NOT EXISTS portal_password_hash    TEXT,
  ADD COLUMN IF NOT EXISTS portal_login_tentativas  INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS portal_bloqueado_ate     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS portal_ultimo_login      TIMESTAMPTZ;

ALTER TABLE gestao_escolar.school_guardians
  ADD COLUMN IF NOT EXISTS portal_password_hash     TEXT,
  ADD COLUMN IF NOT EXISTS portal_login_tentativas   INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS portal_bloqueado_ate      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS portal_ultimo_login       TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS portal_email_verificado   BOOLEAN NOT NULL DEFAULT FALSE;
