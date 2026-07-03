-- ============================================================
-- Down migration 091 (antiga 092): remove colunas de lockout do portal
-- ============================================================

SET search_path TO gestao_escolar, public;

ALTER TABLE school_students
    DROP COLUMN IF EXISTS portal_login_tentativas,
    DROP COLUMN IF EXISTS portal_bloqueado_ate;
