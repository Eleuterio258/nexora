INSERT INTO clientes (
    tenant_id, codigo, nome, email, telefone, nif, endereco,
    limite_credito, credito_usado, pontos_fidelidade, tipo_preco, ativo
)
SELECT
    t.id,
    seed.codigo,
    seed.nome,
    seed.email,
    seed.telefone,
    seed.nif,
    seed.endereco,
    seed.limite_credito,
    seed.credito_usado,
    seed.pontos_fidelidade,
    seed.tipo_preco,
    1
FROM tenants t
CROSS JOIN (
    SELECT 'CLI-0101' AS codigo, 'Mercado Azul' AS nome, 'mercado.azul@demo.mz' AS email, '843000101' AS telefone, '400310101' AS nif, 'Maputo' AS endereco, 10000.0 AS limite_credito, 0.0 AS credito_usado, 80 AS pontos_fidelidade, 'normal' AS tipo_preco
    UNION ALL SELECT 'CLI-0102', 'Restaurante Beira Mar', 'beiramar@demo.mz', '843000102', '400310102', 'Matola', 20000.0, 0.0, 150, 'normal'
    UNION ALL SELECT 'CLI-0103', 'Padaria Central', 'padaria@demo.mz', '843000103', '400310103', 'Maputo', 8000.0, 0.0, 60, 'normal'
    UNION ALL SELECT 'CLI-0104', 'Joana Manuel', 'joana.manuel@demo.mz', '843000104', '400310104', 'Boane', 2500.0, 0.0, 20, 'normal'
    UNION ALL SELECT 'CLI-0105', 'Carlos Zimba', 'carlos.zimba@demo.mz', '843000105', '400310105', 'Marracuene', 1500.0, 0.0, 10, 'normal'
    UNION ALL SELECT 'CLI-0106', 'Hotel Costa Sol', 'compras@costasol.mz', '843000106', '400310106', 'Maputo', 25000.0, 0.0, 220, 'normal'
    UNION ALL SELECT 'CLI-0107', 'Mini Mercado XPTO', 'mmxpto@demo.mz', '843000107', '400310107', 'Matola', 12000.0, 0.0, 95, 'normal'
    UNION ALL SELECT 'CLI-0108', 'Helena Chissano', 'helena@demo.mz', '843000108', '400310108', 'Maputo', 3000.0, 0.0, 35, 'normal'
) seed
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM clientes c WHERE c.codigo = seed.codigo
  );

INSERT INTO fornecedores (tenant_id, nome, contato, telefone, email, endereco, nif, ativo)
SELECT t.id, seed.nome, seed.contato, seed.telefone, seed.email, seed.endereco, seed.nif, 1
FROM tenants t
CROSS JOIN (
    SELECT 'Doces e Snacks SA' AS nome, 'Marcio Ubisse' AS contato, '844000201' AS telefone, 'vendas@snacks.mz' AS email, 'Maputo' AS endereco, '400420201' AS nif
    UNION ALL SELECT 'Casa do Grao', 'Lina Mahumane', '844000202', 'comercial@grao.mz', 'Matola', '400420202'
    UNION ALL SELECT 'Distribuidora Fresh', 'Nelson Cossa', '844000203', 'fresh@demo.mz', 'Boane', '400420203'
) seed
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM fornecedores f WHERE f.tenant_id = t.id AND f.nome = seed.nome
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
    SELECT 'Bebidas' AS categoria, '7891000000061' AS codigo_barras, 'BEB-004' AS sku, 'Sprite 2L' AS nome, 'Refrigerante Sprite 2 litros' AS descricao, 68.0 AS preco_compra, 92.0 AS preco_venda, NULL AS preco_promocao, 26 AS stock_atual, 5 AS stock_minimo, 'un' AS unidade_medida
    UNION ALL SELECT 'Bebidas', '7891000000062', 'BEB-005', 'Fanta Laranja 2L', 'Refrigerante sabor laranja 2 litros', 68.0, 92.0, NULL, 21, 5, 'un'
    UNION ALL SELECT 'Bebidas', '7891000000063', 'BEB-006', 'Agua Tonica 1L', 'Agua tonica 1 litro', 45.0, 62.0, NULL, 19, 4, 'un'
    UNION ALL SELECT 'Alimentacao', '7891000000071', 'ALI-004', 'Feijao Manteiga 1Kg', 'Feijao manteiga embalagem 1Kg', 95.0, 125.0, NULL, 24, 6, 'un'
    UNION ALL SELECT 'Alimentacao', '7891000000072', 'ALI-005', 'Farinha 1Kg', 'Farinha de trigo embalagem 1Kg', 38.0, 52.0, NULL, 33, 8, 'un'
    UNION ALL SELECT 'Alimentacao', '7891000000073', 'ALI-006', 'Esparguete 500g', 'Massa esparguete 500g', 44.0, 58.0, NULL, 28, 8, 'un'
    UNION ALL SELECT 'Alimentacao', '7891000000074', 'ALI-007', 'Bolacha Maria', 'Bolacha maria pacote medio', 28.0, 40.0, NULL, 36, 10, 'un'
    UNION ALL SELECT 'Limpeza', '7891000000081', 'LIM-003', 'Sabao em Po 1Kg', 'Sabao em po para roupa 1Kg', 120.0, 155.0, NULL, 17, 5, 'un'
    UNION ALL SELECT 'Limpeza', '7891000000082', 'LIM-004', 'Esponja Multiuso', 'Esponja multiuso para cozinha', 12.0, 20.0, NULL, 45, 10, 'un'
    UNION ALL SELECT 'Limpeza', '7891000000083', 'LIM-005', 'Amaciante 2L', 'Amaciante para roupa 2 litros', 135.0, 175.0, NULL, 14, 4, 'un'
    UNION ALL SELECT 'Higiene', '7891000000091', 'HIG-003', 'Shampoo 400ml', 'Shampoo uso diario 400ml', 140.0, 185.0, NULL, 18, 5, 'un'
    UNION ALL SELECT 'Higiene', '7891000000092', 'HIG-004', 'Papel Higienico 4un', 'Pacote com 4 rolos', 75.0, 98.0, NULL, 31, 8, 'pct'
    UNION ALL SELECT 'Higiene', '7891000000093', 'HIG-005', 'Creme Corporal 250ml', 'Creme corporal hidratante 250ml', 110.0, 145.0, NULL, 12, 4, 'un'
    UNION ALL SELECT 'Outros', '7891000000101', 'OUT-003', 'Vela Unidade', 'Vela branca unidade', 8.0, 15.0, NULL, 80, 20, 'un'
    UNION ALL SELECT 'Outros', '7891000000102', 'OUT-004', 'Fosforos', 'Caixa de fosforos', 7.0, 12.0, NULL, 55, 15, 'un'
    UNION ALL SELECT 'Outros', '7891000000103', 'OUT-005', 'Saco Plastico', 'Saco plastico medio', 2.0, 5.0, NULL, 300, 50, 'un'
) seed
JOIN categorias c
  ON c.tenant_id = t.id
 AND c.nome = seed.categoria
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM produtos p WHERE p.tenant_id = t.id AND p.sku = seed.sku
  );

INSERT INTO vendas (
    tenant_id, user_id, cliente_id, terminal, subtotal, desconto, imposto, total,
    metodo_pagamento, status, tipo_documento, serie_documento, numero_documento, referencia, observacoes
)
SELECT
    t.id,
    u.id,
    c.id,
    seed.terminal,
    seed.subtotal,
    seed.desconto,
    0,
    seed.total,
    seed.metodo_pagamento,
    'finalizada',
    'FT',
    'FT',
    seed.numero_documento,
    seed.referencia,
    seed.observacoes
FROM tenants t
CROSS JOIN (
    SELECT 'caixa@factpro.local' AS utilizador, 'CLI-0001' AS cliente, 'POS-001' AS terminal, 185.0 AS subtotal, 0.0 AS desconto, 185.0 AS total, 'Dinheiro' AS metodo_pagamento, 1001 AS numero_documento, 'VENDA-DEMO-001' AS referencia, 'Venda demo balcao 1' AS observacoes
    UNION ALL SELECT 'caixa@factpro.local', 'CLI-0104', 'POS-001', 223.0, 10.0, 213.0, 'M-Pesa', 1002, 'VENDA-DEMO-002', 'Venda demo mpesa'
    UNION ALL SELECT 'gestor@factpro.local', 'CLI-0102', 'POS-002', 640.0, 25.0, 615.0, 'Transferencia', 1003, 'VENDA-DEMO-003', 'Venda demo restaurante'
    UNION ALL SELECT 'caixa@factpro.local', 'CLI-0106', 'POS-001', 460.0, 0.0, 460.0, 'Cartao', 1004, 'VENDA-DEMO-004', 'Venda demo hotel'
    UNION ALL SELECT 'gestor@factpro.local', 'CLI-0003', 'POS-002', 315.0, 0.0, 315.0, 'Fiado', 1005, 'VENDA-DEMO-005', 'Venda demo fiado'
    UNION ALL SELECT 'caixa@factpro.local', 'CLI-0107', 'POS-001', 275.0, 15.0, 260.0, 'Dinheiro', 1006, 'VENDA-DEMO-006', 'Venda demo mercado'
) seed
JOIN users u
  ON u.tenant_id = t.id
 AND u.email = seed.utilizador
JOIN clientes c
  ON c.tenant_id = t.id
 AND c.codigo = seed.cliente
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM vendas v WHERE v.tenant_id = t.id AND v.referencia = seed.referencia
  );

INSERT INTO venda_itens (venda_id, produto_id, quantidade, preco_unitario, desconto, total)
SELECT
    v.id,
    p.id,
    seed.quantidade,
    seed.preco_unitario,
    seed.desconto,
    seed.total
FROM tenants t
CROSS JOIN (
    SELECT 'VENDA-DEMO-001' AS referencia, 'BEB-001' AS sku, 1.0 AS quantidade, 95.0 AS preco_unitario, 0.0 AS desconto, 95.0 AS total
    UNION ALL SELECT 'VENDA-DEMO-001', 'ALI-002', 1.0, 55.0, 0.0, 55.0
    UNION ALL SELECT 'VENDA-DEMO-001', 'HIG-001', 1.0, 25.0, 0.0, 25.0
    UNION ALL SELECT 'VENDA-DEMO-001', 'OUT-002', 1.0, 10.0, 0.0, 10.0

    UNION ALL SELECT 'VENDA-DEMO-002', 'LIM-001', 1.0, 65.0, 5.0, 60.0
    UNION ALL SELECT 'VENDA-DEMO-002', 'HIG-004', 1.0, 98.0, 5.0, 93.0
    UNION ALL SELECT 'VENDA-DEMO-002', 'BEB-002', 2.0, 35.0, 0.0, 70.0

    UNION ALL SELECT 'VENDA-DEMO-003', 'ALI-001', 1.0, 315.0, 25.0, 290.0
    UNION ALL SELECT 'VENDA-DEMO-003', 'ALI-006', 2.0, 58.0, 0.0, 116.0
    UNION ALL SELECT 'VENDA-DEMO-003', 'BEB-006', 3.0, 62.0, 0.0, 186.0
    UNION ALL SELECT 'VENDA-DEMO-003', 'ALI-007', 1.0, 48.0, 0.0, 48.0

    UNION ALL SELECT 'VENDA-DEMO-004', 'HIG-003', 1.0, 185.0, 0.0, 185.0
    UNION ALL SELECT 'VENDA-DEMO-004', 'HIG-004', 2.0, 98.0, 0.0, 196.0
    UNION ALL SELECT 'VENDA-DEMO-004', 'OUT-003', 5.0, 15.0, 0.0, 75.0
    UNION ALL SELECT 'VENDA-DEMO-004', 'OUT-004', 1.0, 4.0, 0.0, 4.0

    UNION ALL SELECT 'VENDA-DEMO-005', 'ALI-001', 1.0, 315.0, 0.0, 315.0

    UNION ALL SELECT 'VENDA-DEMO-006', 'ALI-005', 2.0, 52.0, 0.0, 104.0
    UNION ALL SELECT 'VENDA-DEMO-006', 'ALI-007', 1.0, 40.0, 0.0, 40.0
    UNION ALL SELECT 'VENDA-DEMO-006', 'BEB-005', 1.0, 92.0, 10.0, 82.0
    UNION ALL SELECT 'VENDA-DEMO-006', 'OUT-005', 10.0, 5.0, 1.0, 49.0
) seed
JOIN vendas v
  ON v.tenant_id = t.id
 AND v.referencia = seed.referencia
JOIN produtos p
  ON p.tenant_id = t.id
 AND p.sku = seed.sku
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM venda_itens vi WHERE vi.venda_id = v.id AND vi.produto_id = p.id
  );

INSERT INTO pagamentos (venda_id, metodo, valor, referencia, transacao_id, status, processado_em)
SELECT
    v.id,
    seed.metodo,
    seed.valor,
    seed.referencia_pagamento,
    seed.transacao_id,
    'processado',
    '2026-04-10 10:00:00'
FROM tenants t
CROSS JOIN (
    SELECT 'VENDA-DEMO-001' AS referencia_venda, 'Dinheiro' AS metodo, 185.0 AS valor, 'PAG-DEMO-001' AS referencia_pagamento, 'TRX-001' AS transacao_id
    UNION ALL SELECT 'VENDA-DEMO-002', 'M-Pesa', 213.0, 'PAG-DEMO-002', 'TRX-002'
    UNION ALL SELECT 'VENDA-DEMO-003', 'Transferencia', 615.0, 'PAG-DEMO-003', 'TRX-003'
    UNION ALL SELECT 'VENDA-DEMO-004', 'Cartao', 460.0, 'PAG-DEMO-004', 'TRX-004'
    UNION ALL SELECT 'VENDA-DEMO-005', 'Fiado', 0.0, 'PAG-DEMO-005', 'TRX-005'
    UNION ALL SELECT 'VENDA-DEMO-006', 'Dinheiro', 260.0, 'PAG-DEMO-006', 'TRX-006'
) seed
JOIN vendas v
  ON v.tenant_id = t.id
 AND v.referencia = seed.referencia_venda
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM pagamentos p WHERE p.venda_id = v.id AND p.referencia = seed.referencia_pagamento
  );

INSERT INTO contas_receber (cliente_id, venda_id, valor_total, valor_pago, valor_pendente, status, data_vencimento)
SELECT
    c.id,
    v.id,
    315.0,
    0.0,
    315.0,
    'pendente',
    '2026-04-30'
FROM tenants t
JOIN clientes c
  ON c.tenant_id = t.id
 AND c.codigo = 'CLI-0003'
JOIN vendas v
  ON v.tenant_id = t.id
 AND v.referencia = 'VENDA-DEMO-005'
WHERE t.codigo = 'FACTPRO-DEMO'
  AND NOT EXISTS (
      SELECT 1 FROM contas_receber cr WHERE cr.venda_id = v.id
  );
