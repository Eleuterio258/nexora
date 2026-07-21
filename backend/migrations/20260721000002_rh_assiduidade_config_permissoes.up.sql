-- Permissões para configurar o sistema flexível de assiduidade (catálogos
-- de tipos de evento/métodos de marcação e regras por âmbito).
--
-- Segue o mesmo padrão de derivação de 20260712000123_assiduidade_correcao_permissoes.up.sql:
-- quem já vê/gere funcionários passa também a ver/gerir a configuração de
-- assiduidade, sem precisar de atribuição manual adicional.

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT cargo_id, 'assiduidade', 'ver_configuracao'
FROM auth.permissoes_cargo
WHERE modulo = 'recursos-humanos' AND acao = 'ver_funcionarios'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_diretas (user_id, tenant_id, modulo, acao)
SELECT user_id, tenant_id, 'assiduidade', 'ver_configuracao'
FROM auth.permissoes_diretas
WHERE modulo = 'recursos-humanos' AND acao = 'ver_funcionarios'
ON CONFLICT (user_id, tenant_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT cargo_id, 'assiduidade', 'gerir_configuracao'
FROM auth.permissoes_cargo
WHERE modulo = 'recursos-humanos' AND acao = 'gerir_funcionarios'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_diretas (user_id, tenant_id, modulo, acao)
SELECT user_id, tenant_id, 'assiduidade', 'gerir_configuracao'
FROM auth.permissoes_diretas
WHERE modulo = 'recursos-humanos' AND acao = 'gerir_funcionarios'
ON CONFLICT (user_id, tenant_id, modulo, acao) DO NOTHING;
