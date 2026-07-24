-- O módulo 'vendas' não possui rotas/endpoints próprios; a funcionalidade de
-- vendas é tratada pelo módulo POS. Converte permissões legadas de 'vendas'
-- para 'pos.operar_pos' e remove duplicados resultantes.

SET search_path TO auth, public;

-- ── Converte permissões diretas ──────────────────────────────────────────────
INSERT INTO auth.permissoes_diretas (user_id, modulo, acao)
SELECT user_id, 'pos', 'operar_pos'
FROM auth.permissoes_diretas
WHERE modulo = 'vendas'
ON CONFLICT (user_id, modulo, acao) DO NOTHING;

DELETE FROM auth.permissoes_diretas WHERE modulo = 'vendas';

-- ── Converte permissões de cargo ─────────────────────────────────────────────
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT cargo_id, 'pos', 'operar_pos'
FROM auth.permissoes_cargo
WHERE modulo = 'vendas'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

DELETE FROM auth.permissoes_cargo WHERE modulo = 'vendas';

-- ── Remove permissões de tipo (não devem existir, mas garante limpeza) ────────
DELETE FROM auth.permissoes_tipo WHERE modulo = 'vendas';
