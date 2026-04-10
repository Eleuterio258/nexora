'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { stock_item_id } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (stock_item_id) { params.push(stock_item_id); cond.push(`stock_item_id = $${params.length}`); }
    const { rows } = await db.query(
      `SELECT * FROM stock_adjustments WHERE ${cond.join(' AND ')} ORDER BY adjusted_at DESC`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { stock_item_id, adjustment_type, quantity, reason } = req.body;
    if (!stock_item_id || !adjustment_type || !quantity) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'stock_item_id, adjustment_type e quantity são obrigatórios' });
    }
    if (!['positivo', 'negativo'].includes(adjustment_type)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'adjustment_type deve ser positivo ou negativo' });
    }

    const { rows: items } = await client.query(
      `SELECT id, available_quantity FROM stock_items WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [stock_item_id, req.user.tenantId]
    );
    if (!items.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Item de stock não encontrado' });
    }

    if (adjustment_type === 'negativo' && Number(items[0].available_quantity) < Number(quantity)) {
      await client.query('ROLLBACK');
      return res.status(422).json({ error: 'Stock disponível insuficiente para ajuste negativo' });
    }

    const delta = adjustment_type === 'positivo' ? Number(quantity) : -Number(quantity);
    await client.query(
      `UPDATE stock_items SET quantity = quantity + $1, updated_at = NOW() WHERE id = $2`,
      [delta, stock_item_id]
    );

    const { rows } = await client.query(
      `INSERT INTO stock_adjustments (tenant_id, stock_item_id, adjustment_type, quantity, reason)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [req.user.tenantId, stock_item_id, adjustment_type, quantity, reason || null]
    );

    await client.query(
      `INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id)
       VALUES ($1,$2,'ajuste',$3,'stock_adjustment',$4)`,
      [req.user.tenantId, stock_item_id, quantity, rows[0].id]
    );

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

module.exports = { listar, criar };
