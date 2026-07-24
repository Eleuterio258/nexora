-- Permissões para o módulo de assinatura digital.
-- Aplica automaticamente a todos os cargos 'Administrador' existentes.

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT id, 'assinatura-digital', 'ver_documentos'
FROM auth.cargos
WHERE nome = 'Administrador'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT id, 'assinatura-digital', 'gerir_documentos'
FROM auth.cargos
WHERE nome = 'Administrador'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;
