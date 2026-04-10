'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM sales_returns WHERE tenant_id=$1 ORDER BY created_at DESC`,
      [req.user.tenantId]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { customer_id, invoice_id, return_date, observacoes, items } = req.body;
    if (!customer_id || !items?.length) {
      return res.status(400).json({ error: 'customer_id e items são obrigatórios' });
    }

    const ano = new Date().getFullYear();
    const { rows: cnt } = await client.query(
      `SELECT COUNT(*)+1 AS seq FROM sales_returns
        WHERE tenant_id=$1 AND EXTRACT(YEAR FROM created_at)=$2`,
      [req.user.tenantId, ano]
    );
    const numero = `DEV${ano}/${String(cnt[0].seq).padStart(6, '0')}`;

    const { rows } = await client.query(
      `INSERT INTO sales_returns
         (tenant_id, customer_id, invoice_id, numero, return_date, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [req.user.tenantId, customer_id, invoice_id || null, numero,
       return_date || null, observacoes || null, req.user.id]
    );

    for (const it of items) {
      await client.query(
        `INSERT INTO sales_return_items
           (sales_return_id, product_id, quantidade, motivo, estado_produto)
         VALUES ($1,$2,$3,$4,$5)`,
        [rows[0].id, it.product_id, it.quantidade,
         it.motivo || null, it.estado_produto || 'bom']
      );
    }

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function obter(req, res, next) {
  try {
    const [ret, items] = await Promise.all([
      db.query(
        `SELECT * FROM sales_returns WHERE id=$1 AND tenant_id=$2`,
        [req.params.id, req.user.tenantId]
      ),
      db.query(
        `SELECT * FROM sales_return_items WHERE sales_return_id=$1`,
        [req.params.id]
      ),
    ]);
    if (!ret.rows.length) return res.status(404).json({ error: 'Devolução não encontrada' });
    res.json({ ...ret.rows[0], items: items.rows });
  } catch (err) { next(err); }
}

async function receber(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_returns SET status='recebida'
        WHERE id=$1 AND tenant_id=$2 AND status='pendente'
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Devolução não encontrada ou não está pendente' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function processar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_returns SET status='processada'
        WHERE id=$1 AND tenant_id=$2 AND status='recebida'
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Devolução não encontrada ou não está recebida' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, receber, processar };
