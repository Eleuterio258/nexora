'use strict';

const db = require('../config/db');

async function listar(req, res, next) {
  try {
    const { warehouse_id, product_id, abaixo_minimo } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];

    if (warehouse_id)           { params.push(warehouse_id); cond.push(`warehouse_id = $${params.length}`); }
    if (product_id)             { params.push(product_id);   cond.push(`product_id = $${params.length}`); }
    if (abaixo_minimo === 'true') { cond.push('available_quantity < minimum_quantity'); }

    const { rows } = await db.query(
      `SELECT * FROM stock_items WHERE ${cond.join(' AND ')} ORDER BY product_id, warehouse_id`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  try {
    const { product_id, product_variant_id, warehouse_id, minimum_quantity, maximum_quantity } = req.body;
    if (!product_id || !warehouse_id) {
      return res.status(400).json({ error: 'product_id e warehouse_id são obrigatórios' });
    }
    const { rows } = await db.query(
      `INSERT INTO stock_items (tenant_id, product_id, product_variant_id, warehouse_id, minimum_quantity, maximum_quantity)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [
        req.user.tenantId, product_id, product_variant_id || null, warehouse_id,
        minimum_quantity ?? 0, maximum_quantity || null,
      ]
    );
    res.status(201).json(rows[0]);
  } catch (err) { next(err); }
}

async function obter(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM stock_items WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Item de stock não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { minimum_quantity, maximum_quantity } = req.body;
    const { rows } = await db.query(
      `UPDATE stock_items SET
         minimum_quantity = COALESCE($1, minimum_quantity),
         maximum_quantity = COALESCE($2, maximum_quantity),
         updated_at       = NOW()
       WHERE id = $3 AND tenant_id = $4 RETURNING *`,
      [minimum_quantity ?? null, maximum_quantity ?? null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Item de stock não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function entrada(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: items } = await client.query(
      `SELECT id, tenant_id FROM stock_items WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!items.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Item de stock não encontrado' });
    }
    const { quantity, reference_type, reference_id } = req.body;
    if (!quantity || Number(quantity) <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'quantity deve ser positivo' });
    }
    const { rows } = await client.query(
      `UPDATE stock_items SET quantity = quantity + $1, updated_at = NOW()
       WHERE id = $2 RETURNING *`,
      [quantity, req.params.id]
    );
    await client.query(
      `INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id)
       VALUES ($1,$2,'entrada',$3,$4,$5)`,
      [req.user.tenantId, req.params.id, quantity, reference_type || null, reference_id || null]
    );
    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function saida(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: items } = await client.query(
      `SELECT id, tenant_id, available_quantity FROM stock_items WHERE id = $1 AND tenant_id = $2 FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!items.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Item de stock não encontrado' });
    }
    const { quantity, reference_type, reference_id } = req.body;
    if (!quantity || Number(quantity) <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'quantity deve ser positivo' });
    }
    if (Number(items[0].available_quantity) < Number(quantity)) {
      await client.query('ROLLBACK');
      return res.status(422).json({ error: 'Stock disponível insuficiente' });
    }
    const { rows } = await client.query(
      `UPDATE stock_items SET quantity = quantity - $1, updated_at = NOW()
       WHERE id = $2 RETURNING *`,
      [quantity, req.params.id]
    );
    await client.query(
      `INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id)
       VALUES ($1,$2,'saida',$3,$4,$5)`,
      [req.user.tenantId, req.params.id, quantity, reference_type || null, reference_id || null]
    );
    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function listarMovimentos(req, res, next) {
  try {
    const { rows: items } = await db.query(
      `SELECT id FROM stock_items WHERE id = $1 AND tenant_id = $2`,
      [req.params.id, req.user.tenantId]
    );
    if (!items.length) return res.status(404).json({ error: 'Item de stock não encontrado' });
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const { rows } = await db.query(
      `SELECT * FROM stock_movements WHERE stock_item_id = $1
       ORDER BY movement_date DESC
       LIMIT $2 OFFSET $3`,
      [req.params.id, Number(limit), offset]
    );
    res.json(rows);
  } catch (err) { next(err); }
}

module.exports = { listar, criar, obter, actualizar, entrada, saida, listarMovimentos };
