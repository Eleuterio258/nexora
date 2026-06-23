-- Views do modulo de Seguranca

CREATE OR REPLACE VIEW vw_users_permissions AS
SELECT
    u.id AS user_id,
    u.tenant_id,
    u.nome AS user_nome,
    u.email,
    r.codigo AS role_codigo,
    p.codigo AS permission_codigo,
    p.nome AS permission_nome
FROM users u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id
JOIN role_permissions rp ON rp.role_id = r.id
JOIN permissions p ON p.id = rp.permission_id;

CREATE OR REPLACE VIEW vw_users_roles AS
SELECT
    u.id AS user_id,
    u.tenant_id,
    u.nome,
    u.email,
    r.id AS role_id,
    r.codigo,
    r.nome AS role_nome
FROM users u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles r ON r.id = ur.role_id;
