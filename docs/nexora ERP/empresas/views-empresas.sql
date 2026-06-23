-- Views do modulo de Empresas e Multi-Tenant

CREATE OR REPLACE VIEW vw_company_resumo AS
SELECT
    c.id AS company_id,
    c.codigo,
    c.nome,
    c.status,
    c.moeda_base,
    c.timezone,
    ct.nuit,
    ct.regime_iva,
    COUNT(DISTINCT cb.id) AS total_filiais,
    COUNT(DISTINCT cu.user_id) AS total_usuarios
FROM companies c
LEFT JOIN company_tax_info ct ON ct.company_id = c.id
LEFT JOIN company_branches cb ON cb.company_id = c.id
LEFT JOIN company_users cu ON cu.company_id = c.id
GROUP BY c.id, c.codigo, c.nome, c.status, c.moeda_base, c.timezone, ct.nuit, ct.regime_iva;

CREATE OR REPLACE VIEW vw_company_licenses_ativas AS
SELECT
    cl.id,
    cl.company_id,
    c.nome AS company_nome,
    cl.plano,
    cl.status,
    cl.inicia_em,
    cl.expira_em,
    cl.limite_usuarios,
    cl.limite_filiais
FROM company_licenses cl
JOIN companies c ON c.id = cl.company_id
WHERE cl.status = 'ativa';
