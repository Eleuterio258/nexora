-- ============================================================
-- Down migration 090 (antiga 091): reverte a classificação de escopos
-- ============================================================
-- Repõe o escopo de todos os funcionários para 'erp'.
-- Superadmins e outros tipos não são alterados.
-- ============================================================

SET search_path TO auth, public;

UPDATE auth.users
   SET escopo = 'erp',
       updated_at = NOW()
 WHERE tipo = 'funcionario';
