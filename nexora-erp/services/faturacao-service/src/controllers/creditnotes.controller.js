'use strict';

const db = require('../config/db');
const { proximoNumero } = require('../lib/numeracao');
const { calcularLinha, calcularDocumento } = require('../lib/calculos');

async function recalcularTotais(client, ncId) {
  const { rows } = await client.query(
    `SELECT subtotal, 0 AS desconto_valor, imposto_valor, total FROM credit_note_items WHERE credit_note_id=$1`, [ncId]
  );
  const tot = calcularDocumento(rows);
  await client.query(
    `UPDATE credit_notes SET subtotal=$1, imposto_total=$2, total=$3 WHERE id=$4`,
    [tot.subtotal, tot.imposto_total, tot.total, ncId]
  );
}

async function listar(req, res, next) {
  try {
    const { invoice_id, status } = req.query;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (invoice_id) { params.push(invoice_id); cond.push(`invoice_id = $${params.length}`); }
    if (status)     { params.push(status);     cond.push(`status = $${params.length}`); }

    const { rows } = await db.query(
      `SELECT * FROM credit_notes WHERE ${cond.join(' AND ')} ORDER BY created_at DESC`, params
    );
    res.json(rows);
  } catch (err) { next(err); }
}

async function criar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { customer_id, invoice_id, credit_date, motivo, moeda, observacoes } = req.body;
    if (!customer_id || !motivo) return res.status(400).json({ error: 'customer_id e motivo são obrigatórios' });

    const { numero, serie_id } = await proximoNumero(client, req.user.tenantId, 'NC');

    const { rows } = await client.query(
      `INSERT INTO credit_notes (tenant_id, serie_id, customer_id, invoice_id, numero, credit_date, motivo, moeda, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [req.user.tenantId, serie_id, customer_id, invoice_id || null, numero,
       credit_date || null, motivo, moeda || 'MZN', observacoes || null, req.user.id]
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
    const [nc, items] = await Promise.all([
      db.query(`SELECT * FROM credit_notes WHERE id=$1 AND tenant_id=$2`, [req.params.id, req.user.tenantId]),
      db.query(`SELECT * FROM credit_note_items WHERE credit_note_id=$1 ORDER BY id`, [req.params.id]),
    ]);
    if (!nc.rows.length) return res.status(404).json({ error: 'Nota de crédito não encontrada' });
    res.json({ ...nc.rows[0], items: items.rows });
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    const { motivo, observacoes } = req.body;
    const { rows } = await db.query(
      `UPDATE credit_notes SET
         motivo      = COALESCE($1, motivo),
         observacoes = COALESCE($2, observacoes)
       WHERE id=$3 AND tenant_id=$4 AND status='rascunho' RETURNING *`,
      [motivo || null, observacoes || null, req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Nota de crédito não encontrada ou não está em rascunho' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function emitir(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE credit_notes SET status='emitida', emitida_em=NOW()
        WHERE id=$1 AND tenant_id=$2 AND status='rascunho' RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Nota de crédito não encontrada ou não está em rascunho' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function aplicar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { rows: nc } = await client.query(
      `SELECT * FROM credit_notes WHERE id=$1 AND tenant_id=$2 AND status='emitida' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!nc.length) return res.status(404).json({ error: 'Nota de crédito não encontrada ou não está emitida' });
    if (!nc[0].invoice_id) return res.status(422).json({ error: 'Nota de crédito sem fatura original associada' });

    const { rows: inv } = await client.query(
      `SELECT valor_pago, total, status FROM invoices WHERE id=$1 FOR UPDATE`, [nc[0].invoice_id]
    );
    const novoPago = Math.min(Number(inv[0].total), Number(inv[0].valor_pago) + Number(nc[0].total));
    const novoStatus = novoPago >= Number(inv[0].total) ? 'paga' : 'parcialmente_paga';

    await Promise.all([
      client.query(`UPDATE invoices SET valor_pago=$1, status=$2 WHERE id=$3`, [novoPago, novoStatus, nc[0].invoice_id]),
      client.query(`UPDATE credit_notes SET status='aplicada' WHERE id=$1`, [nc[0].id]),
    ]);

    await client.query('COMMIT');
    res.json({ id: nc[0].id, status: 'aplicada' });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

async function cancelar(req, res, next) {
  try {
    const { rows } = await db.query(
      `UPDATE credit_notes SET status='cancelada' WHERE id=$1 AND tenant_id=$2 AND status IN ('rascunho','emitida') RETURNING *`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Nota de crédito não encontrada ou não pode ser cancelada' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function adicionarItem(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows: nc } = await client.query(
      `SELECT id FROM credit_notes WHERE id=$1 AND tenant_id=$2 AND status='rascunho' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!nc.length) return res.status(404).json({ error: 'Nota de crédito não encontrada ou não está em rascunho' });

    const { product_id, descricao, quantidade, preco_unitario, tax_id, imposto_percent } = req.body;
    if (!descricao) return res.status(400).json({ error: 'descricao é obrigatória' });

    const subtotal   = parseFloat((Number(quantidade || 1) * Number(preco_unitario || 0)).toFixed(2));
    const imposValor = parseFloat((subtotal * Number(imposto_percent || 0) / 100).toFixed(2));
    const total      = parseFloat((subtotal + imposValor).toFixed(2));

    const { rows } = await client.query(
      `INSERT INTO credit_note_items (credit_note_id, product_id, descricao, quantidade, preco_unitario, tax_id, imposto_percent, imposto_valor, subtotal, total)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [req.params.id, product_id || null, descricao, quantidade || 1, preco_unitario || 0,
       tax_id || null, imposto_percent || 0, imposValor, subtotal, total]
    );

    await recalcularTotais(client, req.params.id);
    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

module.exports = { listar, criar, obter, actualizar, emitir, aplicar, cancelar, adicionarItem };
