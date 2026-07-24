-- Cria permissões de leitura granular para dados sensíveis de RH e atribui-as
-- automaticamente a quem já tem permissões administrativas equivalentes,
-- preservando o acesso existente após a alteração do router.go.

SET search_path TO auth, public;

-- ── Permissões de cargo ──────────────────────────────────────────────────────
-- Quem processa salários também vê salários e recibos
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT cargo_id, 'recursos-humanos', 'ver_salarios'
FROM auth.permissoes_cargo
WHERE modulo = 'recursos-humanos' AND acao = 'processar_salarios'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT cargo_id, 'recursos-humanos', 'ver_recibos'
FROM auth.permissoes_cargo
WHERE modulo = 'recursos-humanos' AND acao = 'processar_salarios'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

-- Quem gere benefícios também vê benefícios
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT cargo_id, 'recursos-humanos', 'ver_beneficios'
FROM auth.permissoes_cargo
WHERE modulo = 'recursos-humanos' AND acao = 'gerir_beneficios'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

-- Quem gere funcionários também vê processos disciplinares
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT cargo_id, 'recursos-humanos', 'ver_processos_disciplinares'
FROM auth.permissoes_cargo
WHERE modulo = 'recursos-humanos' AND acao = 'gerir_funcionarios'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

-- ── Permissões diretas ───────────────────────────────────────────────────────
INSERT INTO auth.permissoes_diretas (user_id, modulo, acao)
SELECT user_id, 'recursos-humanos', 'ver_salarios'
FROM auth.permissoes_diretas
WHERE modulo = 'recursos-humanos' AND acao = 'processar_salarios'
ON CONFLICT (user_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_diretas (user_id, modulo, acao)
SELECT user_id, 'recursos-humanos', 'ver_recibos'
FROM auth.permissoes_diretas
WHERE modulo = 'recursos-humanos' AND acao = 'processar_salarios'
ON CONFLICT (user_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_diretas (user_id, modulo, acao)
SELECT user_id, 'recursos-humanos', 'ver_beneficios'
FROM auth.permissoes_diretas
WHERE modulo = 'recursos-humanos' AND acao = 'gerir_beneficios'
ON CONFLICT (user_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_diretas (user_id, modulo, acao)
SELECT user_id, 'recursos-humanos', 'ver_processos_disciplinares'
FROM auth.permissoes_diretas
WHERE modulo = 'recursos-humanos' AND acao = 'gerir_funcionarios'
ON CONFLICT (user_id, modulo, acao) DO NOTHING;
