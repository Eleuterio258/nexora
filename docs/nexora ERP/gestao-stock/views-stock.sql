-- Views do modulo de Gestao de Stock

-- Alertas de stock minimo por produto e armazem
CREATE OR REPLACE VIEW vw_stock_alertas_minimo AS
SELECT
    p.id AS product_id,
    p.tenant_id,
    p.codigo AS product_codigo,
    p.nome AS product_nome,
    w.id AS warehouse_id,
    w.nome AS warehouse,
    si.quantity,
    si.reserved_quantity,
    si.available_quantity,
    si.minimum_quantity,
    (si.minimum_quantity - si.quantity) AS quantidade_em_falta
FROM stock_items si
JOIN products p ON p.id = si.product_id
JOIN warehouses w ON w.id = si.warehouse_id
WHERE si.quantity <= si.minimum_quantity
  AND si.minimum_quantity > 0;

-- Posicao de stock actual por produto e armazem
CREATE OR REPLACE VIEW vw_stock_posicao AS
SELECT
    si.tenant_id,
    p.codigo AS product_codigo,
    p.nome AS product_nome,
    pv.codigo AS variant_codigo,
    w.nome AS warehouse,
    wl.nome AS localizacao,
    si.quantity,
    si.reserved_quantity,
    si.available_quantity,
    si.minimum_quantity,
    si.maximum_quantity,
    si.updated_at
FROM stock_items si
JOIN products p ON p.id = si.product_id
JOIN warehouses w ON w.id = si.warehouse_id
LEFT JOIN product_variants pv ON pv.id = si.product_variant_id
LEFT JOIN warehouse_locations wl ON wl.id = si.warehouse_location_id;

-- Movimentos de stock com produto, armazem e referencia de origem
CREATE OR REPLACE VIEW vw_stock_movimentos AS
SELECT
    sm.id,
    sm.tenant_id,
    p.codigo AS product_codigo,
    p.nome AS product_nome,
    w.nome AS warehouse,
    sm.tipo,
    sm.quantity,
    sm.reference_type,
    sm.reference_id,
    sm.movement_date,
    sm.created_at
FROM stock_movements sm
JOIN stock_items si ON si.id = sm.stock_item_id
JOIN products p ON p.id = si.product_id
JOIN warehouses w ON w.id = si.warehouse_id;

-- Reservas activas com produto e armazem
CREATE OR REPLACE VIEW vw_stock_reservas_activas AS
SELECT
    sr.id AS reserva_id,
    sr.tenant_id,
    p.codigo AS product_codigo,
    p.nome AS product_nome,
    w.nome AS warehouse,
    sr.quantity,
    sr.reference_type,
    sr.reference_id,
    sr.reserved_at
FROM stock_reservations sr
JOIN stock_items si ON si.id = sr.stock_item_id
JOIN products p ON p.id = si.product_id
JOIN warehouses w ON w.id = si.warehouse_id
WHERE sr.status = 'ativa';

-- Lotes proximos de expirar (nos proximos 30 dias)
CREATE OR REPLACE VIEW vw_stock_lotes_a_expirar AS
SELECT
    sb.id AS batch_id,
    p.tenant_id,
    p.codigo AS product_codigo,
    p.nome AS product_nome,
    w.nome AS warehouse,
    sb.batch_number,
    sb.manufacture_date,
    sb.expiry_date,
    sb.quantity,
    (sb.expiry_date - CURRENT_DATE) AS dias_para_expirar
FROM stock_batches sb
JOIN stock_items si ON si.id = sb.stock_item_id
JOIN products p ON p.id = si.product_id
JOIN warehouses w ON w.id = si.warehouse_id
WHERE sb.expiry_date IS NOT NULL
  AND sb.expiry_date <= CURRENT_DATE + INTERVAL '30 days'
  AND sb.expiry_date >= CURRENT_DATE
  AND sb.quantity > 0;

-- Resumo de contagens fisicas com divergencias
CREATE OR REPLACE VIEW vw_stock_contagens_divergencias AS
SELECT
    sc.tenant_id,
    sc.numero AS contagem_numero,
    w.nome AS warehouse,
    p.codigo AS product_codigo,
    p.nome AS product_nome,
    sci.system_quantity,
    sci.counted_quantity,
    sci.difference_quantity,
    sc.count_date,
    sc.status
FROM stock_count_items sci
JOIN stock_counts sc ON sc.id = sci.stock_count_id
JOIN stock_items si ON si.id = sci.stock_item_id
JOIN products p ON p.id = si.product_id
JOIN warehouses w ON w.id = sc.warehouse_id
WHERE sci.difference_quantity <> 0;
