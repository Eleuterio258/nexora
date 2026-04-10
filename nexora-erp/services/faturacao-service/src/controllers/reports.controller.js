'use strict';

const db = require('../config/db');

async function salesSummary(req, res, next) {
  try {
    const { data_inicio, data_fim } = req.query;
    if (!data_inicio || !data_fim) return res.status(400).json({ error: 'data_inicio e data_fim são obrigatórios' });

    const { rows } = await db.query(
      `SELECT
         DATE_TRUNC('day', invoice_date) AS dia,
         COUNT(*) AS num_faturas,
         SUM(subtotal)        AS subtotal,
         SUM(desconto_total)  AS descontos,
         SUM(imposto_total)   AS iva,
         SUM(total)           AS total,
         SUM(valor_pago)      AS recebido,
         SUM(saldo_pendente)  AS pendente
       FROM invoices
       WHERE tenant_id=$1 AND invoice_date BETWEEN $2 AND $3 AND status != 'cancelada'
       GROUP BY 1 ORDER BY 1`,
      [req.user.tenantId, data_inicio, data_fim]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function revenueByCustomer(req, res, next) {
  try {
    const { data_inicio, data_fim } = req.query;
    if (!data_inicio || !data_fim) return res.status(400).json({ error: 'data_inicio e data_fim são obrigatórios' });

    const { rows } = await db.query(
      `SELECT customer_id,
         COUNT(*) AS num_faturas,
         SUM(total) AS total,
         SUM(valor_pago) AS recebido,
         SUM(saldo_pendente) AS pendente
       FROM invoices
       WHERE tenant_id=$1 AND invoice_date BETWEEN $2 AND $3 AND status != 'cancelada'
       GROUP BY customer_id ORDER BY total DESC`,
      [req.user.tenantId, data_inicio, data_fim]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function revenueByProduct(req, res, next) {
  try {
    const { data_inicio, data_fim } = req.query;
    if (!data_inicio || !data_fim) return res.status(400).json({ error: 'data_inicio e data_fim são obrigatórios' });

    const { rows } = await db.query(
      `SELECT ii.product_id,
         SUM(ii.quantidade) AS quantidade_total,
         SUM(ii.subtotal)   AS subtotal,
         SUM(ii.total)      AS total
       FROM invoice_items ii
       JOIN invoices i ON i.id = ii.invoice_id
       WHERE i.tenant_id=$1 AND i.invoice_date BETWEEN $2 AND $3 AND i.status != 'cancelada'
       GROUP BY ii.product_id ORDER BY total DESC`,
      [req.user.tenantId, data_inicio, data_fim]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function agingReceivables(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT
         customer_id,
         SUM(CASE WHEN CURRENT_DATE - due_date <= 30  THEN saldo_pendente ELSE 0 END) AS "0_30",
         SUM(CASE WHEN CURRENT_DATE - due_date BETWEEN 31 AND 60  THEN saldo_pendente ELSE 0 END) AS "31_60",
         SUM(CASE WHEN CURRENT_DATE - due_date BETWEEN 61 AND 90  THEN saldo_pendente ELSE 0 END) AS "61_90",
         SUM(CASE WHEN CURRENT_DATE - due_date > 90              THEN saldo_pendente ELSE 0 END) AS "90_mais",
         SUM(saldo_pendente) AS total_pendente
       FROM invoices
       WHERE tenant_id=$1 AND saldo_pendente > 0 AND status NOT IN ('paga','cancelada')
       GROUP BY customer_id ORDER BY total_pendente DESC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function taxSummary(req, res, next) {
  try {
    const { data_inicio, data_fim } = req.query;
    if (!data_inicio || !data_fim) return res.status(400).json({ error: 'data_inicio e data_fim são obrigatórios' });

    const { rows } = await db.query(
      `SELECT it.nome_imposto, it.taxa,
         SUM(it.base_imponivel) AS base_imponivel,
         SUM(it.valor_imposto)  AS valor_iva
       FROM invoice_taxes it
       JOIN invoices i ON i.id = it.invoice_id
       WHERE i.tenant_id=$1 AND i.invoice_date BETWEEN $2 AND $3 AND i.status != 'cancelada'
       GROUP BY it.nome_imposto, it.taxa ORDER BY it.taxa`,
      [req.user.tenantId, data_inicio, data_fim]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function topCustomers(req, res, next) {
  try {
    const { data_inicio, data_fim, limit = 10 } = req.query;
    if (!data_inicio || !data_fim) return res.status(400).json({ error: 'data_inicio e data_fim são obrigatórios' });

    const { rows } = await db.query(
      `SELECT customer_id, SUM(total) AS total_faturado, COUNT(*) AS num_faturas
         FROM invoices
        WHERE tenant_id=$1 AND invoice_date BETWEEN $2 AND $3 AND status != 'cancelada'
        GROUP BY customer_id ORDER BY total_faturado DESC LIMIT $4`,
      [req.user.tenantId, data_inicio, data_fim, Number(limit)]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

module.exports = { salesSummary, revenueByCustomer, revenueByProduct, agingReceivables, taxSummary, topCustomers };
