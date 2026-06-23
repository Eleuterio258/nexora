-- Views do modulo de Gestao de Clientes

CREATE OR REPLACE VIEW vw_customer_resumo AS
SELECT
    c.id AS customer_id,
    c.tenant_id,
    c.codigo,
    c.nome,
    cg.nome AS grupo,
    c.nuit,
    c.telefone,
    c.email,
    COALESCE(ccl.limite_credito, 0) AS limite_credito,
    COALESCE(cb.saldo_atual, 0) AS saldo_atual,
    COALESCE(cb.saldo_vencido, 0) AS saldo_vencido,
    COALESCE(cb.credito_disponivel, 0) AS credito_disponivel,
    c.estado,
    c.created_at,
    c.updated_at
FROM customers c
LEFT JOIN customer_groups cg ON cg.id = c.customer_group_id
LEFT JOIN customer_credit_limits ccl ON ccl.customer_id = c.id AND ccl.ativo = TRUE
LEFT JOIN customer_balances cb ON cb.customer_id = c.id;

CREATE OR REPLACE VIEW vw_customer_payment_summary AS
SELECT
    c.id AS customer_id,
    c.nome,
    COUNT(cp.id) AS total_pagamentos,
    COALESCE(SUM(cp.valor), 0) AS valor_pago,
    MAX(cp.pago_em) AS ultimo_pagamento
FROM customers c
LEFT JOIN customer_payments cp ON cp.customer_id = c.id
GROUP BY c.id, c.nome;

CREATE OR REPLACE VIEW vw_customer_tags AS
SELECT
    c.id AS customer_id,
    c.nome,
    ct.id AS tag_id,
    ct.codigo,
    ct.nome AS tag_nome,
    ct.cor
FROM customer_tag_links ctl
JOIN customers c ON c.id = ctl.customer_id
JOIN customer_tags ct ON ct.id = ctl.customer_tag_id;
