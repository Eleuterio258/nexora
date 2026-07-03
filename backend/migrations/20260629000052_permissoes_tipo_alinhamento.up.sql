-- Alinha permissões padrão por tipo (auth.permissoes_tipo) com o catálogo canónico.
-- Corrige actions genéricas que ficaram órfãs após a migração 046.

SET search_path TO auth, public;

-- ── tenant_admin / empresa ───────────────────────────────────────────────────
-- Actions correctas segundo modules.php e router.go
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao) VALUES
    ('tenant_admin', 'empresa', 'ver_empresa'),
    ('tenant_admin', 'empresa', 'editar_empresa')
ON CONFLICT (tipo, modulo, acao) DO NOTHING;

-- Remove actions genéricas órfãs
DELETE FROM auth.permissoes_tipo
WHERE tipo = 'tenant_admin'
  AND modulo = 'empresa'
  AND acao IN ('ver', 'editar');

-- ── funcionario / pedido-ferias ──────────────────────────────────────────────
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao) VALUES
    ('funcionario', 'pedido-ferias', 'ver_pedidos'),
    ('funcionario', 'pedido-ferias', 'submeter_pedido')
ON CONFLICT (tipo, modulo, acao) DO NOTHING;

DELETE FROM auth.permissoes_tipo
WHERE tipo = 'funcionario'
  AND modulo = 'pedido-ferias'
  AND acao IN ('ver', 'criar');
