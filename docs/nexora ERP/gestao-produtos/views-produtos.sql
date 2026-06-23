-- Views do modulo de Gestao de Produtos

CREATE OR REPLACE VIEW vw_product_summary AS
SELECT
    p.id AS product_id,
    p.tenant_id,
    p.codigo,
    p.nome,
    pc.nome AS categoria,
    psc.nome AS subcategoria,
    pb.nome AS marca,
    pu.nome AS unidade,
    p.tipo,
    p.iva_percentual,
    p.stock_minimo,
    p.ativo,
    p.created_at,
    p.updated_at
FROM products p
LEFT JOIN product_categories pc ON pc.id = p.product_category_id
LEFT JOIN product_subcategories psc ON psc.id = p.product_subcategory_id
LEFT JOIN product_brands pb ON pb.id = p.product_brand_id
LEFT JOIN product_units pu ON pu.id = p.product_unit_id;

CREATE OR REPLACE VIEW vw_product_current_prices AS
SELECT
    p.id AS product_id,
    p.codigo,
    p.nome,
    pv.id AS variant_id,
    pv.nome AS variante,
    pp.tipo_preco,
    pp.moeda,
    pp.valor,
    pp.ativo
FROM product_prices pp
JOIN products p ON p.id = pp.product_id
LEFT JOIN product_variants pv ON pv.id = pp.product_variant_id
WHERE pp.ativo = TRUE;

CREATE OR REPLACE VIEW vw_product_stock_alerts AS
SELECT
    p.id AS product_id,
    p.codigo,
    p.nome,
    pv.id AS variant_id,
    pv.nome AS variante,
    w.id AS warehouse_id,
    w.nome AS armazem,
    ps.quantidade,
    ps.stock_minimo,
    CASE WHEN ps.quantidade <= ps.stock_minimo THEN TRUE ELSE FALSE END AS alerta_stock_minimo
FROM product_stock ps
JOIN products p ON p.id = ps.product_id
LEFT JOIN product_variants pv ON pv.id = ps.product_variant_id
JOIN warehouses w ON w.id = ps.warehouse_id;
