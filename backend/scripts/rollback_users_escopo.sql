-- ============================================================
-- Migration 090: Rollback PARCIAL da coluna escopo em auth.users
-- ============================================================
-- Remove a coluna auth.users.escopo e o respectivo CHECK constraint.
--
-- NOTA: este ficheiro é uma down-migration PARCIAL. Não reverte:
--   - as permissões/cargos ajustados em 086_permissoes_escolares_alinhamento.sql
--   - as atribuições de cargo Administrador em 087_funcionarios_sem_cargo_administrador.sql
--   - os utilizadores de teste criados em 089_seed_utilizadores_teste_escopo.sql
--   - a classificação de escopos em 091_classificar_utilizadores_por_escopo.sql
-- Para um rollback completo da separação ERP/Escola, reverta manualmente
-- essas alterações ou crie down-migrations dedicadas.
--
-- Aplicar apenas se for necessário reverter a coluna escopo.
-- ============================================================

SET search_path TO auth, public;

ALTER TABLE auth.users
    DROP CONSTRAINT IF EXISTS chk_users_escopo;

ALTER TABLE auth.users
    DROP COLUMN IF EXISTS escopo;
