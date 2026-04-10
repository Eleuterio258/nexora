'use strict';

const db = require('../config/db');
const { proximoNumero } = require('../lib/numeracao');

async function listar(req, res, next) {
  try {
    const { sales_order_id, status } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (sales_order_id) { params.push(sales_order_id); cond.push(`sales_order_id = $${params.length}`); }
    if (status)         { params.push(status);          cond.push(`status = $${params.length}`); }

    const { rows } = await db.query(
      `SELECT * FROM sales_deliveries WHERE ${cond.join(' AND ')} ORDER BY created_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { sales_order_id, delivery_date, morada_entrega, observacoes, items } = req.body;
    if (!sales_order_id || !items?.length) {
      return res.status(400).json({ error: 'sales_order_id e items são obrigatórios' });
    }

    const { rows: ord } = await client.query(
      `SELECT * FROM sales_orders
        WHERE id=$1 AND tenant_id=$2 AND status IN ('confirmada','parcial')
        FOR UPDATE`,
      [sales_order_id, req.user.tenantId]
    );
    if (!ord.length) {
      return res.status(404).json({ error: 'Encomenda não encontrada ou não confirmada' });
    }

    const { numero, serie_id } = await proximoNumero(client, req.user.tenantId, 'GR');

    const { rows: del } = await client.query(
      `INSERT INTO sales_deliveries
         (tenant_id, serie_id, sales_order_id, numero, delivery_date, morada_entrega, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [req.user.tenantId, serie_id, sales_order_id, numero,
       delivery_date || null, morada_entrega || null, observacoes || null, req.user.id]
    );

    for (const it of items) {
      await client.query(
        `INSERT INTO sales_delivery_items
           (sales_delivery_id, sales_order_item_id, product_id, quantidade_entregue)
         VALUES ($1,$2,$3,$4)`,
        [del[0].id, it.sales_order_item_id || null, it.product_id, it.quantidade_entregue]
      );
      if (it.sales_order_item_id) {
        await client.query(
          `UPDATE sales_order_items
              SET quantidade_entregue = quantidade_entregue + $1
            WHERE id = $2`,
          [it.quantidade_entregue, it.sales_order_item_id]
        );
      }
    }

    await client.query('COMMIT');
    res.status(201).json(del[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function obter(req, res, next) {
  try {
    const [del, items] = await Promise.all([
      db.query(
        `SELECT * FROM sales_deliveries WHERE id=$1 AND tenant_id=$2`,
        [req.params.id, req.user.tenantId]
      ),
      db.query(
        `SELECT * FROM sales_delivery_items WHERE sales_delivery_id=$1`,
        [req.params.id]
      ),
    ]);
    if (!del.rows.length) return res.status(404).json({ error: 'Guia não encontrada' });
    res.json({ ...del.rows[0], items: items.rows });
  } catch (err) { next(err); }
}

async function confirmar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_deliveries SET status='entregue'
        WHERE id=$1 AND tenant_id=$2 AND status IN ('emitida','em_transito')
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Guia não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function cancelar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_deliveries SET status='cancelada'
        WHERE id=$1 AND tenant_id=$2 AND status IN ('emitida','em_transito')
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Guia não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, confirmar, cancelar };
