'use strict';

const db = require('../config/db');
const { proximoNumero } = require('../lib/numeracao');
const { calcularLinha, calcularDocumento } = require('../lib/calculos');

// ── helpers ──────────────────────────────────────────────────────────────────

async function recalcularTotais(client, quoteId) {
  const { rows } = await client.query(
    `SELECT subtotal, desconto_valor, imposto_valor, total FROM sales_quote_items WHERE sales_quote_id = $1`,
    [quoteId]
  );
  const tot = calcularDocumento(rows);
  await client.query(
    `UPDATE sales_quotes SET subtotal=$1, desconto_total=$2, imposto_total=$3, total=$4 WHERE id=$5`,
    [tot.subtotal, tot.desconto_total, tot.imposto_total, tot.total, quoteId]
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
      `SELECT id, numero, customer_id, quote_date, validade, status, total, moeda, created_at
         FROM sales_quotes WHERE ${cond.join(' AND ')}
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
    const { customer_id, quote_date, validade, moeda, observacoes } = req.body;
    if (!customer_id) return res.status(400).json({ error: 'customer_id é obrigatório' });

    const { numero, serie_id } = await proximoNumero(client, req.user.tenantId, 'ORC');

    const { rows } = await client.query(
      `INSERT INTO sales_quotes (tenant_id, serie_id, customer_id, numero, quote_date, validade, moeda, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [req.user.tenantId, serie_id, customer_id, numero, quote_date || null, validade || null,
       moeda || 'MZN', observacoes || null, req.user.id]
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
    const [quoteRes, itemsRes] = await Promise.all([
      db.query(`SELECT * FROM sales_quotes WHERE id=$1 AND tenant_id=$2`, [req.params.id, req.user.tenantId]),
      db.query(`SELECT * FROM sales_quote_items WHERE sales_quote_id=$1 ORDER BY id`, [req.params.id]),
    ]);
    if (!quoteRes.rows.length) return res.status(404).json({ error: 'Orçamento não encontrado' });
    res.json({ ...quoteRes.rows[0], items: itemsRes.rows });
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { customer_id, validade, observacoes } = req.body;
    const { rows } = await db.query(
      `UPDATE sales_quotes SET
         customer_id = COALESCE($1, customer_id),
         validade    = COALESCE($2, validade),
         observacoes = COALESCE($3, observacoes)
       WHERE id=$4 AND tenant_id=$5 AND status='rascunho'
       RETURNING *`,
      [customer_id || null, validade || null, observacoes || null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Orçamento não encontrado ou não está em rascunho' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function eliminar(req, res, next) {
  try {
    const { rowCount } = await db.query(
      `DELETE FROM sales_quotes WHERE id=$1 AND tenant_id=$2 AND status='rascunho'`,
      [req.params.id, req.user.tenantId]
    );
    if (!rowCount) return res.status(404).json({ error: 'Orçamento não encontrado ou não está em rascunho' });
    res.status(204).send();
  } catch (err) { next(err); }
}

async function enviar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_quotes SET status='enviado' WHERE id=$1 AND tenant_id=$2 AND status='rascunho' RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Orçamento não encontrado ou não está em rascunho' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function aprovar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_quotes SET status='aprovado' WHERE id=$1 AND tenant_id=$2 AND status='enviado' RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Orçamento não encontrado ou não está enviado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function rejeitar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE sales_quotes SET status='rejeitado' WHERE id=$1 AND tenant_id=$2 AND status IN ('enviado','aprovado') RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Orçamento não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function converter(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    // Busca orçamento aprovado
    const { rows: qRows } = await client.query(
      `SELECT * FROM sales_quotes WHERE id=$1 AND tenant_id=$2 AND status='aprovado' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!qRows.length) return res.status(404).json({ error: 'Orçamento não encontrado ou não está aprovado' });
    const quote = qRows[0];

    const { rows: items } = await client.query(
      `SELECT * FROM sales_quote_items WHERE sales_quote_id=$1`, [quote.id]
    );

    // Gera número da encomenda
    const { numero, serie_id } = await proximoNumero(client, req.user.tenantId, 'ENC');

    const { rows: oRows } = await client.query(
      `INSERT INTO sales_orders
         (tenant_id, serie_id, customer_id, sales_quote_id, numero, moeda, subtotal, desconto_total, imposto_total, total, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
      [quote.tenant_id, serie_id, quote.customer_id, quote.id, numero, quote.moeda,
       quote.subtotal, quote.desconto_total, quote.imposto_total, quote.total,
       quote.observacoes, req.user.id]
    );
    const order = oRows[0];

    // Copia as linhas
    for (const it of items) {
      await client.query(
        `INSERT INTO sales_order_items
           (sales_order_id, product_id, descricao, quantidade, preco_unitario, desconto_percent, desconto_valor,
            tax_id, imposto_percent, imposto_valor, subtotal, total)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
        [order.id, it.product_id, it.descricao, it.quantidade, it.preco_unitario,
         it.desconto_percent, it.desconto_valor, it.tax_id, it.imposto_percent,
         it.imposto_valor, it.subtotal, it.total]
      );
    }

    // Marca orçamento como convertido
    await client.query(`UPDATE sales_quotes SET status='convertido' WHERE id=$1`, [quote.id]);

    await client.query('COMMIT');
    res.status(201).json(order);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

// ── Items ────────────────────────────────────────────────────────────────────

async function adicionarItem(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { rows: qRows } = await client.query(
      `SELECT id FROM sales_quotes WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!qRows.length) return res.status(404).json({ error: 'Orçamento não encontrado ou não está em rascunho' });

    const { product_id, descricao, quantidade, preco_unitario, desconto_percent, tax_id, imposto_percent } = req.body;
    if (!product_id || !quantidade || preco_unitario === undefined) {
      return res.status(400).json({ error: 'product_id, quantidade e preco_unitario são obrigatórios' });
    }

    const calc = calcularLinha({ quantidade, preco_unitario, desconto_percent, imposto_percent });

    const { rows } = await client.query(
      `INSERT INTO sales_quote_items
         (sales_quote_id, product_id, descricao, quantidade, preco_unitario, desconto_percent, desconto_valor,
          tax_id, imposto_percent, imposto_valor, subtotal, total)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
      [req.params.id, product_id, descricao || null, quantidade, preco_unitario,
       desconto_percent || 0, calc.desconto_valor, tax_id || null, imposto_percent || 0,
       calc.imposto_valor, calc.subtotal, calc.total]
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
    const { rows: qRows } = await client.query(
      `SELECT id FROM sales_quotes WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!qRows.length) return res.status(404).json({ error: 'Orçamento não encontrado ou não está em rascunho' });

    const { quantidade, preco_unitario, desconto_percent, imposto_percent, descricao, tax_id } = req.body;
    const { rows: current } = await client.query(
      `SELECT * FROM sales_quote_items WHERE id=$1 AND sales_quote_id=$2`, [req.params.item_id, req.params.id]
    );
    if (!current.length) return res.status(404).json({ error: 'Linha não encontrada' });

    const merged = {
      quantidade:       quantidade       ?? current[0].quantidade,
      preco_unitario:   preco_unitario   ?? current[0].preco_unitario,
      desconto_percent: desconto_percent ?? current[0].desconto_percent,
      imposto_percent:  imposto_percent  ?? current[0].imposto_percent,
    };
    const calc = calcularLinha(merged);

    const { rows } = await client.query(
      `UPDATE sales_quote_items SET
         descricao        = COALESCE($1, descricao),
         quantidade        = $2,
         preco_unitario    = $3,
         desconto_percent  = $4,
         desconto_valor    = $5,
         tax_id            = COALESCE($6, tax_id),
         imposto_percent   = $7,
         imposto_valor     = $8,
         subtotal          = $9,
         total             = $10
       WHERE id = $11 RETURNING *`,
      [descricao || null, merged.quantidade, merged.preco_unitario, merged.desconto_percent,
       calc.desconto_valor, tax_id || null, merged.imposto_percent, calc.imposto_valor,
       calc.subtotal, calc.total, req.params.item_id]
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
    const { rows: qRows } = await client.query(
      `SELECT id FROM sales_quotes WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!qRows.length) return res.status(404).json({ error: 'Orçamento não encontrado ou não está em rascunho' });

    const { rowCount } = await client.query(
      `DELETE FROM sales_quote_items WHERE id=$1 AND sales_quote_id=$2`, [req.params.item_id, req.params.id]
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

module.exports = { listar, criar, obter, actualizar, eliminar, enviar, aprovar, rejeitar, converter, adicionarItem, actualizarItem, removerItem };
