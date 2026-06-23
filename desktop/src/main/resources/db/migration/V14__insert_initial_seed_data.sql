INSERT INTO tenants (codigo, nome, nif, email, telefone, endereco, configuracao, ativo)
SELECT
    'FACTPRO-DEMO',
    'FactPro Demo',
    '400000000',
    'admin@factpro.local',
    '840000000',
    'Maputo, Mozambique',
    '{"moeda":"MZN","idioma":"pt_MZ","pais":"MZ"}',
    1
WHERE NOT EXISTS (
    SELECT 1 FROM tenants WHERE codigo = 'FACTPRO-DEMO'
);

INSERT INTO users (tenant_id, role_id, nome, email, senha_hash, telefone, ativo, tentativas_falhas)
SELECT
    t.id,
    r.id,
    'Administrador',
    'admin@factpro.local',
    '$2a$12$wQoK6KgM5gvfC0RyK2h9TeYuEjmjsxfzR/m0w1vcSiBw6.zHDbEQW',
    '840000000',
    1,
    0
FROM tenants t
JOIN roles r ON r.nome = 'Admin'
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM users WHERE email = 'admin@factpro.local'
  );

INSERT INTO categorias (tenant_id, nome, descricao, cor, ativo)
SELECT t.id, seed.nome, seed.descricao, seed.cor, 1
FROM tenants t
CROSS JOIN (
    SELECT 'Bebidas' AS nome, 'Refrigerantes, agua, sumos e bebidas diversas' AS descricao, '#2563EB' AS cor
    UNION ALL SELECT 'Alimentacao', 'Produtos alimentares e mercearia', '#16A34A'
    UNION ALL SELECT 'Limpeza', 'Artigos de limpeza e higiene', '#0891B2'
    UNION ALL SELECT 'Higiene', 'Produtos de higiene pessoal', '#DB2777'
    UNION ALL SELECT 'Outros', 'Categoria geral para artigos diversos', '#6B7280'
) seed
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1
      FROM categorias c
      WHERE c.tenant_id = t.id
        AND c.nome = seed.nome
  );

INSERT INTO clientes (tenant_id, codigo, nome, email, telefone, nif, endereco, limite_credito, credito_usado, pontos_fidelidade, tipo_preco, ativo)
SELECT t.id, seed.codigo, seed.nome, seed.email, seed.telefone, seed.nif, seed.endereco, seed.limite_credito, 0, seed.pontos_fidelidade, 'normal', 1
FROM tenants t
CROSS JOIN (
    SELECT 'CLI-0001' AS codigo, 'Consumidor Final' AS nome, NULL AS email, NULL AS telefone, NULL AS nif, 'Balcao' AS endereco, 0.0 AS limite_credito, 0 AS pontos_fidelidade
    UNION ALL SELECT 'CLI-0002', 'Cliente Empresa', 'compras@cliente-empresa.mz', '841111111', '400100200', 'Maputo', 15000.0, 120
    UNION ALL SELECT 'CLI-0003', 'Cliente Credito', 'credito@cliente.mz', '842222222', '400100201', 'Matola', 5000.0, 40
) seed
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1
      FROM clientes c
      WHERE c.codigo = seed.codigo
  );

INSERT INTO fornecedores (tenant_id, nome, contato, telefone, email, endereco, nif, ativo)
SELECT t.id, seed.nome, seed.contato, seed.telefone, seed.email, seed.endereco, seed.nif, 1
FROM tenants t
CROSS JOIN (
    SELECT 'Distribuidora Central' AS nome, 'Paulo Matavele' AS contato, '843333333' AS telefone, 'vendas@distribuidora.mz' AS email, 'Maputo' AS endereco, '400200300' AS nif
    UNION ALL SELECT 'Bebidas do Sul', 'Ana Chauque', '844444444', 'comercial@bebidasdosul.mz', 'Matola', '400200301'
    UNION ALL SELECT 'Higiene Pro', 'Joao Cossa', '845555555', 'suporte@higienepro.mz', 'Boane', '400200302'
) seed
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1
      FROM fornecedores f
      WHERE f.tenant_id = t.id
        AND f.nome = seed.nome
  );
