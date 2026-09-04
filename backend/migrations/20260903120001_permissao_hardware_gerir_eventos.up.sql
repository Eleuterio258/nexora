-- Permissão 'hardware:gerir_eventos' — reprocessamento administrativo de
-- hardware.device_events (Fase 5, item 4, de
-- docs/analise-transactional-outbox-backends.md: "permitir replay seguro").
--
-- Backfill apenas: concede a permissão a qualquer cargo que já tenha
-- 'hardware:gerir_dispositivos' (mesmo padrão de
-- 20260812070000_pos_permissoes_granulares.up.sql). Não altera
-- auth.criar_cargos_padrao() para tenants novos — confirmado que a versão
-- actual da função (20260812070001_cargos_padrao_pos.up.sql) já não atribui
-- NENHUMA permissão do módulo 'hardware' a cargo nenhum (regressão
-- pré-existente, introduzida nessa migração ao substituir por completo o
-- corpo anterior sem transportar o bloco de hardware que existia em
-- 20260727093000_permissoes_cargos_padrao_finas.up.sql). Corrigir isso é
-- mais do que esta migração se propõe a fazer — fica registado aqui para
-- não ficar escondido.

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT DISTINCT pc.cargo_id, 'hardware', 'gerir_eventos'
  FROM auth.permissoes_cargo pc
 WHERE pc.modulo = 'hardware' AND pc.acao = 'gerir_dispositivos'
   AND NOT EXISTS (
       SELECT 1 FROM auth.permissoes_cargo ex
        WHERE ex.cargo_id = pc.cargo_id AND ex.modulo = 'hardware' AND ex.acao = 'gerir_eventos'
   )
ON CONFLICT DO NOTHING;
