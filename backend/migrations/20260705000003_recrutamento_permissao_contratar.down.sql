-- ============================================================
-- Migration down: remove permissão recrutamento.contratar
-- ============================================================

SET search_path TO auth, public;

DELETE FROM permissoes_cargo  WHERE modulo = 'recrutamento' AND acao = 'contratar';
DELETE FROM permissoes_diretas WHERE modulo = 'recrutamento' AND acao = 'contratar';
DELETE FROM permissoes_tipo   WHERE modulo = 'recrutamento' AND acao = 'contratar';
