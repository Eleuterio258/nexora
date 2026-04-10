'use strict';

const db = require('../config/db');
const { proximoNumero } = require('../lib/numeracao');
const { calcularLinha, calcularDocumento } = require('../lib/calculos');

// ── helpers ──────────────────────────────────────────────────────────────────

async function recalcularTotais(client, orderId) {
  const { rows } = await client.query(
    `SELECT subtotal, desconto_valor, imposto_valor, total FROM sales_order_items WHERE sales_order_id = $1`,
    [orderId]
  );
  const tot = calcularDocumento(rows);
  await client.query(
    `UPDATE sales_orders SET subtotal=$1, desconto_total=$2, imposto_total=$3, total=$4 WHERE id=$5`,
    [tot.subtotal, tot.desconto_total, tot.imposto_total, tot.total, orderId]
  );
  return tot;
}

// ── controllers ───────────────────────────────────────────────────────────────

async function listar(req, res, next) {
  try {
    const { status, customer_id, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (status)      { params.push(status);      cond.push(`status = $${params.length}`); }
    if (customer_id) { params.push(customer_id); cond.push(`customer_id = $${params.length}`); }
    params.push(Number(limit), offset);

    const { rows } = await db.query(
      `SELECT id, numero, customer_id, order_date, status, total, moeda, created_at
         FROM sales_orders WHERE ${cond.join(' AND ')}
        ORDER BY created_at DESC
        LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { customer_id, data_entrega_prevista, moeda, observacoes } = req.body;
    if (!customer_id) return res.status(400).json({ error: 'customer_id é obrigatório' });

    const { numero, serie_id } = await proximoNumero(client, req.user.tenantId, 'ENC');
    const { rows } = await client.query(
      `INSERT INTO sales_orders
         (tenant_id, serie_id, customer_id, numero, data_entrega_prevista, moeda, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [req.user.tenantId, serie_id, customer_id, numero,
       data_entrega_prevista || null, moeda || 'MZN', observacoes || null, req.user.id]
    );
    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function obter(req, res, next) {
  try {
    const [ord, items, delivs] = await Promise.all([
      db.query(`SELECT * FROM sales_orders WHERE id=$1 AND tenant_id=$2`, [req.params.id, req.user.tenantId]),
      db.query(`SELECT * FROM sales_order_items WHERE sales_order_id=$1 ORDER BY id`, [req.params.id]),
      db.query(`SELECT id, numero, delivery_date, status FROM sales_deliveries WHERE sales_order_id=$1`, [req.params.id]),
    ]);
    if (!ord.rows.length) return res.status(404).json({ error: 'Encomenda não encontrada' });
    res.json({ ...ord.rows[0], items: items.rows, deliveries: delivs.rows });
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { data_entrega_prevista, observacoes } = req.body;
    const { rows } = await db.query(
      `UPDATE sales_orders SET
         data_entrega_prevista = COALESCE($1, data_entrega_prevista),
         observacoes           = COALESCE($2, observacoes)
       WHERE id=$3 AND tenant_id=$4 AND status='rascunho'
       RETURNING *`,
      [data_entrega_prevista || null, observacoes || null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Encomenda não encontrada ou não está em rascunho' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function confirmar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_orders SET status='confirmada'
        WHERE id=$1 AND tenant_id=$2 AND status='rascunho'
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Encomenda não encontrada ou não está em rascunho' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function cancelar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_orders SET status='cancelada'
        WHERE id=$1 AND tenant_id=$2 AND status IN ('rascunho','confirmada')
        RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Encomenda não encontrada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

// ── Items ────────────────────────────────────────────────────────────────────

async function adicionarItem(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: ord } = await client.query(
      `SELECT id FROM sales_orders WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!ord.length) return res.status(404).json({ error: 'Encomenda não encontrada ou não está em rascunho' });

    const { product_id, descricao, quantidade, preco_unitario, desconto_percent, tax_id, imposto_percent } = req.body;
    if (!product_id || !quantidade || preco_unitario === undefined) {
      return res.status(400).json({ error: 'product_id, quantidade e preco_unitario são obrigatórios' });
    }

    const calc = calcularLinha({ quantidade, preco_unitario, desconto_percent, imposto_percent });
    const { rows } = await client.query(
      `INSERT INTO sales_order_items
         (sales_order_id, product_id, descricao, quantidade, preco_unitario,
          desconto_percent, desconto_valor, tax_id, imposto_percent, imposto_valor, subtotal, total)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
      [req.params.id, product_id, descricao || null, quantidade, preco_unitario,
       desconto_percent || 0, calc.desconto_valor, tax_id || null,
       imposto_percent || 0, calc.imposto_valor, calc.subtotal, calc.total]
    );

    await recalcularTotais(client, req.params.id);
    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function actualizarItem(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: ord } = await client.query(
      `SELECT id FROM sales_orders WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!ord.length) return res.status(404).json({ error: 'Encomenda não encontrada ou não está em rascunho' });

    const { rows: cur } = await client.query(
      `SELECT * FROM sales_order_items WHERE id=$1 AND sales_order_id=$2`,
      [req.params.item_id, req.params.id]
    );
    if (!cur.length) return res.status(404).json({ error: 'Linha não encontrada' });

    const merged = {
      quantidade:       req.body.quantidade       ?? cur[0].quantidade,
      preco_unitario:   req.body.preco_unitario   ?? cur[0].preco_unitario,
      desconto_percent: req.body.desconto_percent ?? cur[0].desconto_percent,
      imposto_percent:  req.body.imposto_percent  ?? cur[0].imposto_percent,
    };
    const calc = calcularLinha(merged);

    const { rows } = await client.query(
      `UPDATE sales_order_items SET
         quantidade        = $1,
         preco_unitario    = $2,
         desconto_percent  = $3,
         desconto_valor    = $4,
         imposto_percent   = $5,
         imposto_valor     = $6,
         subtotal          = $7,
         total             = $8
       WHERE id = $9 RETURNING *`,
      [merged.quantidade, merged.preco_unitario, merged.desconto_percent, calc.desconto_valor,
       merged.imposto_percent, calc.imposto_valor, calc.subtotal, calc.total, req.params.item_id]
    );

    await recalcularTotais(client, req.params.id);
    await client.query('COMMIT');
    res.json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function removerItem(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: ord } = await client.query(
      `SELECT id FROM sales_orders WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!ord.length) return res.status(404).json({ error: 'Encomenda não encontrada' });

    const { rowCount } = await client.query(
      `DELETE FROM sales_order_items WHERE id=$1 AND sales_order_id=$2`,
      [req.params.item_id, req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Linha não encontrada' });

    await recalcularTotais(client, req.params.id);
    await client.query('COMMIT');
    res.status(204).send();
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

module.exports = {
  listar, criar, obter, actualizar, confirmar, cancelar,
  adicionarItem, actualizarItem, removerItem,
};
