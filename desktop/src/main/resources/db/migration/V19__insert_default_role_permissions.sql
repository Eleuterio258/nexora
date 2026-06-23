-- Inserir permissoes padrao para menus (acesso a modulos)
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('menu:dashboard', 'menu', 'view', 'Acesso ao Dashboard'),
    ('menu:pos', 'menu', 'view', 'Acesso ao POS'),
    ('menu:vendas', 'menu', 'view', 'Acesso ao modulo de Vendas'),
    ('menu:produtos', 'menu', 'view', 'Acesso ao modulo de Produtos'),
    ('menu:clientes', 'menu', 'view', 'Acesso ao modulo de Clientes'),
    ('menu:stock', 'menu', 'view', 'Acesso ao modulo de Stock'),
    ('menu:compras', 'menu', 'view', 'Acesso ao modulo de Compras'),
    ('menu:fornecedores', 'menu', 'view', 'Acesso ao modulo de Fornecedores'),
    ('menu:relatorios', 'menu', 'view', 'Acesso ao modulo de Relatorios'),
    ('menu:configuracoes', 'menu', 'view', 'Acesso ao modulo de Configuracoes'),
    ('menu:usuarios', 'menu', 'view', 'Acesso a gestao de Usuarios'),
    ('menu:roles', 'menu', 'view', 'Acesso a gestao de Roles'),
    ('menu:auditoria', 'menu', 'view', 'Acesso aos logs de Auditoria'),
    ('menu:contas_receber', 'menu', 'view', 'Acesso as Contas a Receber');

-- Permissoes avancadas por modulo (CRUD)
-- Vendas
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('vendas:create', 'vendas', 'create', 'Criar novas vendas'),
    ('vendas:update', 'vendas', 'update', 'Atualizar vendas existentes'),
    ('vendas:delete', 'vendas', 'delete', 'Eliminar vendas'),
    ('vendas:cancel', 'vendas', 'cancel', 'Cancelar vendas'),
    ('vendas:recibo', 'vendas', 'recibo', 'Gerar recibos');

-- Produtos
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('produtos:create', 'produtos', 'create', 'Criar novos produtos'),
    ('produtos:update', 'produtos', 'update', 'Atualizar produtos'),
    ('produtos:delete', 'produtos', 'delete', 'Eliminar produtos');

-- Clientes
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('clientes:create', 'clientes', 'create', 'Criar novos clientes'),
    ('clientes:update', 'clientes', 'update', 'Atualizar clientes'),
    ('clientes:delete', 'clientes', 'delete', 'Eliminar clientes');

-- Stock
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('stock:create', 'stock', 'create', 'Registrar movimentos de stock'),
    ('stock:update', 'stock', 'update', 'Ajustar stock'),
    ('stock:delete', 'stock', 'delete', 'Eliminar movimentos de stock');

-- Compras
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('compras:create', 'compras', 'create', 'Criar novas compras'),
    ('compras:update', 'compras', 'update', 'Atualizar compras'),
    ('compras:delete', 'compras', 'delete', 'Eliminar compras');

-- Fornecedores
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('fornecedores:create', 'fornecedores', 'create', 'Criar novos fornecedores'),
    ('fornecedores:update', 'fornecedores', 'update', 'Atualizar fornecedores'),
    ('fornecedores:delete', 'fornecedores', 'delete', 'Eliminar fornecedores');

-- Usuarios
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('usuarios:create', 'usuarios', 'create', 'Criar novos usuarios'),
    ('usuarios:update', 'usuarios', 'update', 'Atualizar usuarios'),
    ('usuarios:delete', 'usuarios', 'delete', 'Eliminar usuarios');

-- Roles
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('roles:manage', 'roles', 'manage', 'Gerir roles e permissoes');

-- Configuracoes
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('configuracoes:database', 'configuracoes', 'database', 'Alterar configuracoes da base de dados'),
    ('configuracoes:backup', 'configuracoes', 'backup', 'Realizar backups');

-- ============================================
-- ASSOCIAR PERMISSOES AOS ROLES
-- ============================================

-- Admin: TODAS as permissoes
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions;

-- Vendedor: Permissoes limitadas
-- Menus: Dashboard, POS, Vendas, Clientes, Produtos, Stock
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions WHERE nome IN (
    'menu:dashboard', 'menu:pos', 'menu:vendas', 'menu:clientes', 'menu:produtos', 'menu:stock',
    'vendas:create', 'vendas:recibo',
    'clientes:create',
    'produtos:view'
);

-- Gerente de Stock: Gestao de inventario
-- Menus: Dashboard, Produtos, Stock, Compras, Fornecedores
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE nome IN (
    'menu:dashboard', 'menu:produtos', 'menu:stock', 'menu:compras', 'menu:fornecedores',
    'produtos:create', 'produtos:update',
    'stock:create', 'stock:update',
    'compras:create', 'compras:update',
    'fornecedores:create', 'fornecedores:update'
);

