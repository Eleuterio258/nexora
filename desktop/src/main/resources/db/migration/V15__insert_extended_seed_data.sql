INSERT INTO users (tenant_id, role_id, nome, email, senha_hash, telefone, ativo, tentativas_falhas)
SELECT
    t.id,
    r.id,
    'Gestor Loja',
    'gestor@factpro.local',
    '$2a$12$wQoK6KgM5gvfC0RyK2h9TeYuEjmjsxfzR/m0w1vcSiBw6.zHDbEQW',
    '841234567',
    1,
    0
FROM tenants t
JOIN roles r ON r.nome = 'Gestor'
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM users WHERE email = 'gestor@factpro.local'
  );

INSERT INTO users (tenant_id, role_id, nome, email, senha_hash, telefone, ativo, tentativas_falhas)
SELECT
    t.id,
    r.id,
    'Operador Caixa',
    'caixa@factpro.local',
    '$2a$12$wQoK6KgM5gvfC0RyK2h9TeYuEjmjsxfzR/m0w1vcSiBw6.zHDbEQW',
    '842345678',
    1,
    0
FROM tenants t
JOIN roles r ON r.nome = 'Caixa'
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM users WHERE email = 'caixa@factpro.local'
  );

INSERT INTO produtos (
    tenant_id, categoria_id, codigo_barras, sku, nome, descricao,
    preco_compra, preco_venda, preco_promocao, stock_atual, stock_minimo,
    unidade_medida, composto, ativo
)
SELECT
    t.id,
    c.id,
    seed.codigo_barras,
    seed.sku,
    seed.nome,
    seed.descricao,
    seed.preco_compra,
    seed.preco_venda,
    seed.preco_promocao,
    seed.stock_atual,
    seed.stock_minimo,
    seed.unidade_medida,
    0,
    1
FROM tenants t
CROSS JOIN (
    SELECT 'Bebidas' AS categoria, '7891000000011' AS codigo_barras, 'BEB-001' AS sku, 'Coca-Cola 2L' AS nome, 'Refrigerante Coca-Cola garrafa 2 litros' AS descricao, 70.0 AS preco_compra, 95.0 AS preco_venda, 89.0 AS preco_promocao, 24 AS stock_atual, 5 AS stock_minimo, 'un' AS unidade_medida
    UNION ALL SELECT 'Bebidas', '7891000000012', 'BEB-002', 'Agua Mineral 1.5L', 'Agua mineral garrafa 1.5 litros', 22.0, 35.0, NULL, 30, 8, 'un'
    UNION ALL SELECT 'Bebidas', '7891000000013', 'BEB-003', 'Sumo Laranja 1L', 'Sumo de laranja embalagem 1 litro', 55.0, 78.0, NULL, 18, 5, 'un'
    UNION ALL SELECT 'Alimentacao', '7891000000021', 'ALI-001', 'Arroz 5Kg', 'Arroz branco saco 5Kg', 250.0, 315.0, 299.0, 15, 4, 'un'
    UNION ALL SELECT 'Alimentacao', '7891000000022', 'ALI-002', 'Acucar 1Kg', 'Acucar branco embalagem 1Kg', 42.0, 55.0, NULL, 40, 10, 'un'
    UNION ALL SELECT 'Alimentacao', '7891000000023', 'ALI-003', 'Oleo 2L', 'Oleo alimentar garrafa 2 litros', 150.0, 185.0, NULL, 16, 6, 'un'
    UNION ALL SELECT 'Limpeza', '7891000000031', 'LIM-001', 'Detergente 500ml', 'Detergente liquido para louca 500ml', 48.0, 65.0, NULL, 22, 6, 'un'
    UNION ALL SELECT 'Limpeza', '7891000000032', 'LIM-002', 'Lixivia 1L', 'Lixivia multiuso embalagem 1 litro', 35.0, 50.0, NULL, 16, 5, 'un'
    UNION ALL SELECT 'Higiene', '7891000000041', 'HIG-001', 'Sabonete 125g', 'Sabonete perfumado 125g', 18.0, 25.0, NULL, 60, 12, 'un'
    UNION ALL SELECT 'Higiene', '7891000000042', 'HIG-002', 'Pasta Dental 90g', 'Pasta dental protecao total 90g', 65.0, 85.0, NULL, 28, 8, 'un'
    UNION ALL SELECT 'Outros', '7891000000051', 'OUT-001', 'Pilhas AA 2un', 'Cartela com 2 pilhas AA', 45.0, 60.0, NULL, 14, 4, 'un'
    UNION ALL SELECT 'Outros', '7891000000052', 'OUT-002', 'Isqueiro', 'Isqueiro recarregavel', 22.0, 35.0, NULL, 22, 6, 'un'
) seed
JOIN categorias c
  ON c.tenant_id = t.id
 AND c.nome = seed.categoria
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1
      FROM produtos p
      WHERE p.tenant_id = t.id
        AND p.sku = seed.sku
  );

INSERT INTO compras (tenant_id, fornecedor_id, user_id, total, status, data_compra, observacoes)
SELECT
    t.id,
    f.id,
    u.id,
    seed.total,
    'recebida',
    seed.data_compra,
    seed.observacoes
FROM tenants t
CROSS JOIN (
    SELECT 'Distribuidora Central' AS fornecedor, 'admin@factpro.local' AS utilizador, 11160.0 AS total, '2026-04-01' AS data_compra, 'Compra inicial de alimentacao e bebidas' AS observacoes
    UNION ALL SELECT 'Higiene Pro', 'gestor@factpro.local', 5630.0, '2026-04-02', 'Compra inicial de higiene e limpeza'
) seed
JOIN fornecedores f
  ON f.tenant_id = t.id
 AND f.nome = seed.fornecedor
JOIN users u
  ON u.tenant_id = t.id
 AND u.email = seed.utilizador
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1
      FROM compras c
      WHERE c.tenant_id = t.id
        AND c.observacoes = seed.observacoes
  );

INSERT INTO compra_items (compra_id, produto_id, quantidade, preco_unitario, total)
SELECT
    c.id,
    p.id,
    seed.quantidade,
    seed.preco_unitario,
    seed.total
FROM tenants t
CROSS JOIN (
    SELECT 'Compra inicial de alimentacao e bebidas' AS compra_obs, 'BEB-001' AS sku, 24.0 AS quantidade, 70.0 AS preco_unitario, 1680.0 AS total
    UNION ALL SELECT 'Compra inicial de alimentacao e bebidas', 'BEB-002', 30.0, 22.0, 660.0
    UNION ALL SELECT 'Compra inicial de alimentacao e bebidas', 'BEB-003', 18.0, 55.0, 990.0
    UNION ALL SELECT 'Compra inicial de alimentacao e bebidas', 'ALI-001', 15.0, 250.0, 3750.0
    UNION ALL SELECT 'Compra inicial de alimentacao e bebidas', 'ALI-002', 40.0, 42.0, 1680.0
    UNION ALL SELECT 'Compra inicial de alimentacao e bebidas', 'ALI-003', 16.0, 150.0, 2400.0
    UNION ALL SELECT 'Compra inicial de higiene e limpeza', 'LIM-001', 22.0, 48.0, 1056.0
    UNION ALL SELECT 'Compra inicial de higiene e limpeza', 'LIM-002', 16.0, 35.0, 560.0
    UNION ALL SELECT 'Compra inicial de higiene e limpeza', 'HIG-001', 60.0, 18.0, 1080.0
    UNION ALL SELECT 'Compra inicial de higiene e limpeza', 'HIG-002', 28.0, 65.0, 1820.0
    UNION ALL SELECT 'Compra inicial de higiene e limpeza', 'OUT-001', 14.0, 45.0, 630.0
    UNION ALL SELECT 'Compra inicial de higiene e limpeza', 'OUT-002', 22.0, 22.0, 484.0
) seed
JOIN compras c
  ON c.tenant_id = t.id
 AND c.observacoes = seed.compra_obs
JOIN produtos p
  ON p.tenant_id = t.id
 AND p.sku = seed.sku
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1
      FROM compra_items ci
      WHERE ci.compra_id = c.id
        AND ci.produto_id = p.id
  );

INSERT INTO stock_movimentos (produto_id, tipo, quantidade, motivo, referencia, user_id)
SELECT
    p.id,
    'entrada',
    seed.quantidade,
    'Stock inicial',
    seed.referencia,
    u.id
FROM tenants t
CROSS JOIN (
    SELECT 'BEB-001' AS sku, 24.0 AS quantidade, 'COMPRA-INICIAL-001' AS referencia
    UNION ALL SELECT 'BEB-002', 30.0, 'COMPRA-INICIAL-001'
    UNION ALL SELECT 'BEB-003', 18.0, 'COMPRA-INICIAL-001'
    UNION ALL SELECT 'ALI-001', 15.0, 'COMPRA-INICIAL-001'
    UNION ALL SELECT 'ALI-002', 40.0, 'COMPRA-INICIAL-001'
    UNION ALL SELECT 'ALI-003', 16.0, 'COMPRA-INICIAL-001'
    UNION ALL SELECT 'LIM-001', 22.0, 'COMPRA-INICIAL-002'
    UNION ALL SELECT 'LIM-002', 16.0, 'COMPRA-INICIAL-002'
    UNION ALL SELECT 'HIG-001', 60.0, 'COMPRA-INICIAL-002'
    UNION ALL SELECT 'HIG-002', 28.0, 'COMPRA-INICIAL-002'
    UNION ALL SELECT 'OUT-001', 14.0, 'COMPRA-INICIAL-002'
    UNION ALL SELECT 'OUT-002', 22.0, 'COMPRA-INICIAL-002'
) seed
JOIN produtos p
  ON p.tenant_id = t.id
 AND p.sku = seed.sku
JOIN users u
  ON u.tenant_id = t.id
 AND u.email = 'admin@factpro.local'
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1
      FROM stock_movimentos sm
      WHERE sm.produto_id = p.id
        AND sm.tipo = 'entrada'
        AND sm.referencia = seed.referencia
  );
