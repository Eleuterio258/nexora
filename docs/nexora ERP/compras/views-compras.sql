-- Views do modulo de Compras

CREATE OR REPLACE VIEW vw_supplier_summary AS
SELECT
    s.id AS supplier_id,
    s.tenant_id,
    s.codigo,
    s.nome,
    s.nuit,
    s.telefone,
    s.email,
    COALESCE(sb.saldo_atual, 0) AS saldo_atual,
    COALESCE(sb.saldo_vencido, 0) AS saldo_vencido,
    COUNT(DISTINCT si.id) AS total_faturas,
    MAX(si.data_fatura) AS ultima_fatura,
    s.estado
FROM suppliers s
LEFT JOIN supplier_balances sb ON sb.supplier_id = s.id
LEFT JOIN supplier_invoices si ON si.supplier_id = s.id
GROUP BY s.id, s.tenant_id, s.codigo, s.nome, s.nuit, s.telefone, s.email, sb.saldo_atual, sb.saldo_vencido, s.estado;

CREATE OR REPLACE VIEW vw_supplier_payment_summary AS
SELECT
    s.id AS supplier_id,
    s.nome,
    COUNT(sp.id) AS total_pagamentos,
    COALESCE(SUM(sp.valor), 0) AS valor_pago,
    MAX(sp.pago_em) AS ultimo_pagamento
FROM suppliers s
LEFT JOIN supplier_payments sp ON sp.supplier_id = s.id
GROUP BY s.id, s.nome;
