-- Adicionar permissao de menu para Notificacoes
INSERT OR IGNORE INTO permissions (nome, recurso, acao, descricao) VALUES
    ('menu:notificacoes', 'menu', 'view', 'Acesso as Notificacoes');

-- Associar ao role Administrador (todas as permissoes ja sao atribuidas na V19, mas garantimos)
INSERT OR IGNORE INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions WHERE nome = 'menu:notificacoes';
