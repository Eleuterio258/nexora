'use strict';

const db = require('../config/db');
const { proximoNumero } = require('../lib/numeracao');

async function listar(req, res, next) {
  try {
    const { invoice_id, status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const params = [req.user.tenantId];
    const cond = ['tenant_id = $1'];
    if (invoice_id) { params.push(invoice_id); cond.push(`invoice_id = $${params.length}`); }
    if (status)     { params.push(status);     cond.push(`status = $${params.length}`); }
    params.push(Number(limit), offset);

    const { rows } = await db.query(
      `SELECT * FROM invoice_receipts WHERE ${cond.join(' AND ')}
        ORDER BY payment_date DESC
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

    const { invoice_id, payment_date, payment_method_id, valor, referencia, observacoes } = req.body;
    if (!invoice_id || !valor) return res.status(400).json({ error: 'invoice_id e valor são obrigatórios' });

    // Valida fatura
    const { rows: inv } = await client.query(
      `SELECT id, total, valor_pago, status FROM invoices WHERE id=$1 AND tenant_id=$2 FOR UPDATE`,
      [invoice_id, req.user.tenantId]
    );
    if (!inv.length) return res.status(404).json({ error: 'Fatura não encontrada' });
    if (['paga', 'cancelada'].includes(inv[0].status)) {
      return res.status(422).json({ error: 'Fatura já paga ou cancelada' });
    }
    if (Number(valor) > Number(inv[0].total) - Number(inv[0].valor_pago)) {
      return res.status(422).json({ error: 'Valor superior ao saldo pendente' });
    }

    const { numero, serie_id } = await proximoNumero(client, req.user.tenantId, 'RB');

    const { rows } = await client.query(
      `INSERT INTO invoice_receipts (tenant_id, serie_id, invoice_id, numero, payment_date, payment_method_id, valor, referencia, observacoes, criado_por)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [req.user.tenantId, serie_id, invoice_id, numero, payment_date || null,
       payment_method_id || null, valor, referencia || null, observacoes || null, req.user.id]
    );

    // Actualiza valor pago na fatura atomicamente
    const novoPago = Number(inv[0].valor_pago) + Number(valor);
    const novoStatus = novoPago >= Number(inv[0].total) ? 'paga' : 'parcialmente_paga';
    await client.query(
      `UPDATE invoices SET valor_pago=$1, status=$2 WHERE id=$3`,
      [novoPago, novoStatus, invoice_id]
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
    const { rows } = await db.query(
      `SELECT * FROM invoice_receipts WHERE id=$1 AND tenant_id=$2`,
      [req.params.id, req.user.tenantId]
    );
    if (!rows.length) return res.status(404).json({ error: 'Recibo não encontrado' });
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function cancelar(req, res, next) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const { rows: rec } = await client.query(
      `SELECT * FROM invoice_receipts WHERE id=$1 AND tenant_id=$2 AND status='confirmado' FOR UPDATE`,
      [req.params.id, req.user.tenantId]
    );
    if (!rec.length) return res.status(404).json({ error: 'Recibo não encontrado ou não pode ser cancelado' });

    await client.query(`UPDATE invoice_receipts SET status='cancelado' WHERE id=$1`, [rec[0].id]);

    // Reverte o valor pago na fatura
    const { rows: inv } = await client.query(
      `SELECT valor_pago, total FROM invoices WHERE id=$1 FOR UPDATE`, [rec[0].invoice_id]
    );
    const novoPago = Math.max(0, Number(inv[0].valor_pago) - Number(rec[0].valor));
    const novoStatus = novoPago >= Number(inv[0].total) ? 'paga'
                     : novoPago > 0 ? 'parcialmente_paga'
                     : 'emitida';
    await client.query(`UPDATE invoices SET valor_pago=$1, status=$2 WHERE id=$3`, [novoPago, novoStatus, rec[0].invoice_id]);

    await client.query('COMMIT');
    res.json({ id: rec[0].id, status: 'cancelado' });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally { client.release(); }
}

module.exports = { listar, criar, obter, cancelar };
