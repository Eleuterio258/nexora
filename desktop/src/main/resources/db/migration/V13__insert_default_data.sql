INSERT INTO permissions (nome, recurso, acao, descricao) VALUES
    ('users_create', 'users', 'create', 'Criar utilizadores'),
    ('users_read', 'users', 'read', 'Ver utilizadores'),
    ('users_update', 'users', 'update', 'Atualizar utilizadores'),
    ('users_delete', 'users', 'delete', 'Eliminar utilizadores'),
    ('vendas_create', 'vendas', 'create', 'Criar vendas'),
    ('vendas_read', 'vendas', 'read', 'Ver vendas'),
    ('vendas_cancel', 'vendas', 'cancel', 'Cancelar vendas'),
    ('produtos_create', 'produtos', 'create', 'Criar produtos'),
    ('produtos_read', 'produtos', 'read', 'Ver produtos'),
    ('produtos_update', 'produtos', 'update', 'Atualizar produtos'),
    ('produtos_delete', 'produtos', 'delete', 'Eliminar produtos'),
    ('clientes_create', 'clientes', 'create', 'Criar clientes'),
    ('clientes_read', 'clientes', 'read', 'Ver clientes'),
    ('relatorios_read', 'relatorios', 'read', 'Ver relatorios');

INSERT INTO roles (tenant_id, nome, descricao) VALUES
    (NULL, 'Admin', 'Acesso total ao sistema'),
    (NULL, 'Gestor', 'Gestor - Produtos, vendas, relatorios, clientes, stock'),
    (NULL, 'Caixa', 'Operador de caixa - Vendas apenas');

INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions;

INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions WHERE recurso != 'users';

INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE recurso = 'vendas' AND acao IN ('create', 'read');
