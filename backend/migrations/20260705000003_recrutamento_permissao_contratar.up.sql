-- ============================================================
-- Migration: Permissão específica para contratar candidatos
-- ============================================================
-- Cria a permissão granular 'recrutamento.contratar' e herda-a
-- automaticamente para utilizadores/cargos que já possuem
-- 'recrutamento.gerir_candidaturas', garantindo compatibilidade.
-- ============================================================

SET search_path TO auth, public;

-- 1. Garantir que a permissão existe nas tabelas de permissões
--    (as tabelas usadas pelo RBAC do middleware são permissoes_cargo,
--     permissoes_diretas e permissoes_tipo).
INSERT INTO permissoes_cargo (cargo_id, modulo, acao)
SELECT DISTINCT cargo_id, 'recrutamento', 'contratar'
  FROM permissoes_cargo
 WHERE modulo = 'recrutamento'
   AND acao   = 'gerir_candidaturas'
   AND NOT EXISTS (
       SELECT 1 FROM permissoes_cargo pc2
        WHERE pc2.cargo_id = permissoes_cargo.cargo_id
          AND pc2.modulo   = 'recrutamento'
          AND pc2.acao     = 'contratar'
   );

INSERT INTO permissoes_diretas (user_id, modulo, acao)
SELECT DISTINCT user_id, 'recrutamento', 'contratar'
  FROM permissoes_diretas
 WHERE modulo = 'recrutamento'
   AND acao   = 'gerir_candidaturas'
   AND NOT EXISTS (
       SELECT 1 FROM permissoes_diretas pd2
        WHERE pd2.user_id = permissoes_diretas.user_id
          AND pd2.modulo   = 'recrutamento'
          AND pd2.acao     = 'contratar'
   );

INSERT INTO permissoes_tipo (tipo, modulo, acao)
SELECT DISTINCT tipo, 'recrutamento', 'contratar'
  FROM permissoes_tipo
 WHERE modulo = 'recrutamento'
   AND acao   = 'gerir_candidaturas'
   AND NOT EXISTS (
       SELECT 1 FROM permissoes_tipo pt2
        WHERE pt2.tipo   = permissoes_tipo.tipo
          AND pt2.modulo = 'recrutamento'
          AND pt2.acao   = 'contratar'
   )
ON CONFLICT (tipo, modulo, acao) DO NOTHING;
