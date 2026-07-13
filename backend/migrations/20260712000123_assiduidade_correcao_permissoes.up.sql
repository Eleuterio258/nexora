-- Permissões para pedidos de correção de ponto.

-- Self-service: todo funcionário pode submeter/consultar/cancelar os
-- próprios pedidos de correcção de ponto (mesmo padrão de
-- 'assiduidade'/'justificar', ver 20260629000045_permissoes_tipo.up.sql).
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao)
VALUES ('funcionario', 'assiduidade', 'corrigir_ponto')
ON CONFLICT (tipo, modulo, acao) DO NOTHING;

-- RH: quem já aprova ausências também aprova correcções de ponto —
-- deriva a nova permissão de quem já tem 'recursos-humanos'/'aprovar_ausencias'
-- (mesmo padrão de 20260629000055_rh_permissoes_sensiveis.up.sql).
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT cargo_id, 'assiduidade', 'aprovar_correcao'
FROM auth.permissoes_cargo
WHERE modulo = 'recursos-humanos' AND acao = 'aprovar_ausencias'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_diretas (user_id, modulo, acao)
SELECT user_id, 'assiduidade', 'aprovar_correcao'
FROM auth.permissoes_diretas
WHERE modulo = 'recursos-humanos' AND acao = 'aprovar_ausencias'
ON CONFLICT (user_id, modulo, acao) DO NOTHING;
